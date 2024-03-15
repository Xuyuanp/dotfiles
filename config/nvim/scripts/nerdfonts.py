#!/usr/bin/env python
import requests
from bs4 import BeautifulSoup


def main():
    rsp = requests.get("https://www.nerdfonts.com/cheat-sheet")
    soup = BeautifulSoup(rsp.text, "html.parser")

    script = soup.find("script")
    if not script or not script.text:
        return

    script = script.text.strip("\n").removeprefix("const glyphs = ")
    glyphs = eval(script)

    for name, code in glyphs.items():
        print(f"{code:<5} {chr(int(code, 16))} {name}")


if __name__ == "__main__":
    main()
