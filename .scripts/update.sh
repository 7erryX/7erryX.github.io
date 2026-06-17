#! /bin/zsh
#echo "Check/Update theme version"
#npm install hexo-theme-redefine@latest
echo "Refresh hexo blog system"
npx hexo clean
# 删除追番数据
# npx hexo bangumi -d
# 删除追剧数据
# npx hexo cinema -d
# 删除游戏数据
# npx hexo game -d
npx hexo generate
# 更新追番数据
npx hexo bangumi -u
# 使用 bili 源时显示追番进度（需要 SESSDATA）
# npx hexo bangumi -u 'your_sessdata_here'
# 更新追剧数据
npx hexo cinema -u
# 更新游戏数据
npx hexo game -u
npx hexo deploy
