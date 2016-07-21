cp site/_posts/2016-02-25-welcome-to-cd-demo.markdown site/_posts/$(date +%Y-%m-%d)-my-test-post.markdown
vi site/_posts/$(date +%Y-%m-%d)-my-test-post.markdown
git add site/_posts/$(date +%Y-%m-%d)-my-test-post.markdown
git commit -m "Demo change"
git push origin $1
