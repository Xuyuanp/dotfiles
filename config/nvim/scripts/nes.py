#!/usr/bin/env python
import json
import os
import sys
from abc import ABC, abstractmethod

import requests


class Adapter(ABC):
    @property
    @abstractmethod
    def token(self) -> str:
        pass

    @property
    @abstractmethod
    def base_url(self) -> str:
        pass

    @property
    @abstractmethod
    def model(self) -> str:
        pass

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }

    def ask(self, payload):
        rsp = requests.post(
            f"{self.base_url}/chat/completions",
            json=payload,
            headers=self.headers,
            stream=True,
        )
        rsp.raise_for_status()
        output = ""
        for line in rsp.iter_lines(decode_unicode=True):
            if not line:
                continue
            if line.startswith("data:"):
                line = line[5:].strip()
            if line == "[DONE]":
                break
            data = json.loads(line)
            if "choices" in data and len(data["choices"]) > 0:
                output += data["choices"][0]["delta"].get("content", "")
        print(output)


class Copilot(Adapter):
    _USER_AGENT = "vscode-chat/dev"
    _OAUTH_TOKEN_URL = "https://api.github.com/copilot_internal/v2/token"

    @property
    def _oauth_token(self) -> str:
        config_dir = os.environ.get(
            "XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config")
        )

        with open(os.path.join(config_dir, "github-copilot/apps.json")) as f:
            obj = json.load(f)
            for key, value in obj.items():
                if key.startswith("github.com:"):
                    return value["oauth_token"]
            raise RuntimeError("Could not find token")

    @property
    def token(self) -> str:
        rsp = requests.get(
            self._OAUTH_TOKEN_URL,
            headers={
                "Authorization": f"Bearer {self._oauth_token}",
                "Accept": "application/json",
                "User-Agent": self._USER_AGENT,
            },
        )
        rsp.raise_for_status()
        token = rsp.json()["token"]
        return token

    @property
    def base_url(self) -> str:
        # return "https://api.githubcopilot.com"
        return "https://proxy.business.githubcopilot.com"

    @property
    def model(self) -> str:
        return os.environ.get("COPILOT_MODEL", "gpt-4o")

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Copilot-Integration-Id": "vscode-chat",
            "editor-version": "Neovim/0.10.0",
            "editor-plugin-version": "nes/0.1.0",
            "User-Agent": self._USER_AGENT,
        }


example = """
{"snippy":{"enabled":false},"model":"copilot-nes-v","n":1,"stream":true,"messages":[{"role":"system","content":"Keep your answe
rs short and impersonal.\nThe programmer will provide you with a set of recently viewed files, their recent edits, and a snippe
t of code that is being actively edited.\n\nWhen helping the programmer, your goals are:\n- Make only the necessary changes as
indicated by the context.\n- Avoid unnecessary rewrites and make only the necessary changes, using ellipses to indicate partial
 code where appropriate.\n- Ensure all specified additions, modifications, and new elements (e.g., methods, parameters, functio
n calls) are included in the response.\n- Adhere strictly to the provided pattern, structure, and content, including matching t
he exact structure and formatting of the expected response.\n- Maintain the integrity of the existing code while making necessa
ry updates.\n- Provide complete and detailed code snippets without omissions, ensuring all necessary parts such as additional c
lasses, methods, or specific steps are included.\n- Keep the programmer on the pattern that you think they are on.\n- Consider
what edits need to be made next, if any.\n\nWhen responding to the programmer, you must follow these rules:\n- Only answer with
 the updated code. The programmer will copy and paste your code as is in place of the programmer's provided snippet.\n- Match t
he expected response exactly, even if it includes errors or corruptions, to ensure consistency.\n- Do not alter method signatur
es, add or remove return values, or modify existing logic unless explicitly instructed.\n- The current cursor position is indic
ated by <|cursor|>. You must keep the cursor position the same in your response. Do not remove <|cursor|>.\n- You must ONLY rep
ly using the tag: <next-version>.\n"},{"role":"user","content":"These are the files I'm working on, before I started making cha
nges to them:\n<original_code>\ntest.lua:\n1│local function fuck(x)\n2│    vim.print(x, 10)\n3│end\n4│\n5│fuck(1)\n6│local M =
{}\n7│\n8│function M.open_floating_window()\n9│    local bufnr = vim.api.nvim_create_buf(false, true)\n10│    local winnr = vim
.api.nvim_open_win(bufnr, false, {})\n11│    vim.api.nvim_win_set_config(winnr, {})\n12│    return winnr, bufnr, 0\n13│end\n14│
\n15│function M.sort(a)\n16│    table.sort(a, function(x, y)\n17│        return x < y\n18│    end)\n19│    --\n20│end\n21│\n22│
return M\n</original_code>\n\nThis is a sequence of edits that I made on these files, starting from the oldest to the newest:\n
<edits_to_original_code>\n```\n---test.lua:\n+++test.lua:\n@@ -2 +2 @@\n-    vim.print(x, 10)\n+    vim.print(x, 100)\n\n```\n<
/edits_to_original_code>\n\nHere is the piece of code I am currently editing in test.lua:\n\n<current-version>\n```lua\nlocal f
unction fuck(x)\n    vim.print(x, 100<|cursor|>)\nend\n\nfuck(1)\nlocal M = {}\n\nfunction M.open_floating_window()\n    local
bufnr = vim.api.nvim_create_buf(false, true)\n    local winnr = vim.api.nvim_open_win(bufnr, false, {})\n    vim.api.nvim_win_s
et_config(winnr, {})\n    return winnr, bufnr, 0\n```\n</current-version>\n\nBased on my most recent edits, what will I do next
? Rewrite the code between <current-version> and </current-version> based on what I will do next. Do not skip any lines. Do not
 be lazy.\n"}],"temperature":0,"top_p":1,"prediction":{"content":"<next-version>\n```go\nlocal function fuck(x)\n    vim.print(
x, 100<|cursor|>)\nend\n\nfuck(1)\nlocal M = {}\n\nfunction M.open_floating_window()\n    local bufnr = vim.api.nvim_create_buf
(false, true)\n    local winnr = vim.api.nvim_open_win(bufnr, false, {})\n    vim.api.nvim_win_set_config(winnr, {})\n    retur
n winnr, bufnr, 0\n```\n</next-version>","type":"content"}}
"""


def main():
    # payload = json.loads("".join(example.split("\n")))
    payload = json.load(sys.stdin)
    adapter = Copilot()
    adapter.ask(payload)


if __name__ == "__main__":
    main()
