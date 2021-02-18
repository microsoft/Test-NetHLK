# This file is to help reload the nested modules if a change was made.

remove-module helpers -Force -ErrorAction SilentlyContinue
remove-module datatypes -Force -ErrorAction SilentlyContinue
remove-module Test-NicProperties -Force -ErrorAction SilentlyContinue

ipmo .\Test-NICProperties.psd1 -Force
