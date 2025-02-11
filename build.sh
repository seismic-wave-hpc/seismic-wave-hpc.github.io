#!/bin/bash

cd src
quarto render
rsync -avz ./_site/* ../doc/
touch ../doc/.nojekyll 
