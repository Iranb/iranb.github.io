# upload files to github

git add *
git commit -m "update files"
git push -f origin main

# deploy hexo
hexo clean
hexo g -d
echo "Success !!!"