#!/usr/bin/env python3
import argparse


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="demo-minimal",
        description="AI Software Station demo CLI",
        add_help=True,
    )
    parser.add_argument(
        "--version",
        action="version",
        version="demo-minimal 0.1.0",
    )
    parser.add_argument(
        "--name",
        metavar="NAME",
        help="print a greeting for NAME",
    )

    args = parser.parse_args()

    if args.name:
        print(f"demo-minimal: hello {args.name}")
    else:
        print("demo-minimal: AI Software Station demo OK")


if __name__ == "__main__":
    main()
