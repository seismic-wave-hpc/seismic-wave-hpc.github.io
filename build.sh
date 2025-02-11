#!/bin/bash

cd src
quarto render
rsync -avz ./_site/* ../docs/
