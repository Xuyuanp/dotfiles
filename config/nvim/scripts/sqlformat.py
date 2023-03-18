#!/usr/bin/env python3
import sys

import sqlparse


def format_sql(contents):
    for identifier in range(10):
        contents = contents.replace(f"?{identifier}", f"__id_{identifier}")

    result = sqlparse.format(
        contents,
        indent_column=True,
        strip_comments=False,
        use_space_around_operators=True,
        keywork_case="upper",
        identifier_case="lower",
        reindent=True,
        output_format="sql",
        indent_after_first=False,
        wrap_after=80,
        comma_first=True,
    )
    for identifier in range(10):
        result = result.replace(f"__id_{identifier}", f"?{identifier}")

    return result.strip()


def main():
    contents = sys.stdin.read()
    result = format_sql(contents)
    print(result)


if __name__ == "__main__":
    main()
