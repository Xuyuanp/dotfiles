#!/usr/bin/env python

import requests
from bs4 import BeautifulSoup

def main():
    rsp = requests.get('https://www.nerdfonts.com/cheat-sheet')
    soup = BeautifulSoup(rsp.text, 'html.parser')

    columns = soup.find_all('div', attrs={'class': 'column'})
    icons = [(
        col.find('div', attrs={'class': 'codepoint'}).text,
        col.find('div', attrs={'class': 'class-name'}).text,
    ) for col in columns]

    for code, name in icons:
        print(f'{code} {chr(int(code, 16))} {name}')


if __name__ == "__main__":
    main()
