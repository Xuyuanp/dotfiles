import json
import sys

import openai


def main():
    messages = json.load(sys.stdin)

    rsps = openai.ChatCompletion.create(
        model="gpt-3.5-turbo", messages=messages, stream=True
    )
    for rsp in rsps:
        assert isinstance(rsp, dict)
        if content := rsp.get("choices", [{}])[0].get("delta", {}).get("content"):
            print(content, end="", flush=True)


if __name__ == "__main__":
    main()
