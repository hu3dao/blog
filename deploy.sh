#!/usr/bin/env sh

# 忽略错误
set -e

git add .
git commit -m 'add'
git push

# 构建
npm run docs:build

# 进入待发布的目录
cd docs/.vitepress/dist


git init
git add -A
git commit -m 'deploy'

# 如果部署到 https://<USERNAME>.github.io
git push -f git@github.com:hu3dao/hu3dao.github.io.git master

cd -
