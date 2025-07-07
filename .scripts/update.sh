#! /bin/zsh
#echo "Check/Update theme version"
#npm install hexo-theme-redefine@latest
echo "Refresh hexo blog system"
hexo clean
hexo generate 
hexo bangumi -u
hexo cinema -u
hexo deploy
