task :readme do
	`pandoc doc/README.md -t markdown_github -o README.md`
end

task :test do
	`./test/test-mcollector.rb`
	`./test/test-minstructor.rb`
end
