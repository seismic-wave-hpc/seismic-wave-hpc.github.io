#!/bin/bash

cd src
quarto render
rsync -avz --delete ./_site/* ../docs/
