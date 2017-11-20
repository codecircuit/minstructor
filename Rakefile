task :readme => ["doc/README.md"] do
	`pandoc doc/README.md -t gfm -o README.md`
end

task :test do
	puts `./test/test-minstructor.rb`
	puts `./test/test-mcollector.rb`
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
		install_path = man1dir + File.basename(manf)
		`cp -f #{manf} #{install_path}`

		# INSTALL SCRIPTS
		script = File.expand_path("#{t}.rb")
		install_path = default_d + "/#{t}"
		`cp -f #{script} #{install_path}`
	end
end
