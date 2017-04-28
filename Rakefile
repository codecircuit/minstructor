task :readme => ["doc/README.md"] do
	`pandoc doc/README.md -t markdown_github -o README.md`
end

task :test do
	`./test/test-minstructor.rb`
	`./test/test-mcollector.rb`
end

directory "build"


targets = ["minstructor", "mcollector"]

targets.each do |t|
	file "build/#{t}.1.gz" => ["build", "doc/#{t}.md"] do
		`pandoc -t man -s doc/#{t}.md -o build/#{t}.1.gz`
	end
end

task :man => targets.map { |t| "build/#{t}.1.gz"} 

task :default => [:man]

task :install => [:default] do

	default_d = "/usr/local/bin"
	mandir = `man -w`.chomp.split(':')[-1]

	[default_d, mandir].each do |d|
		if !File.directory?(d)
			puts "ERROR: directory #{d} does not exist"
			exit 1
		end
		if !File.writable?(d)
			puts "ERROR: you have no permissions to write at #{d}"
			exit 1
		end
	end

	targets.map do |t|
		# INSTALL MAN PAGES
		manf = File.expand_path("build/#{t}.1.gz")
		man1dir = "#{mandir}/man1/"
		link = man1dir + File.basename(manf)
		File.symlink(manf, link) if !File.exists?(link)

		# INSTALL SCRIPTS
		script = File.expand_path("#{t}.rb")
		link = default_d + "/#{t}"
		File.symlink(script, link) if !File.exists?(link)
	end
end
