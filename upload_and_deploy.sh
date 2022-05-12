# upload files to github

git add *
git commit -m "update files"
git push origin main

# deploy hexo
hexo clean
hexo g
hexo d