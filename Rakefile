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


def which(cmd)
	exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
		exts.each { |ext|
			exe = File.join(path, "#{cmd}#{ext}")
			return exe if File.executable?(exe) && !File.directory?(exe)
		}
	end
	return ""
end

task :install => [:default] do

	default_d = "/usr/local/bin"

	###########
	# SCRIPTS #
	###########
	[default_d].each do |d|
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
		# INSTALL SCRIPTS
		script = File.expand_path("#{t}.rb")
		install_path = default_d + "/#{t}"
		`cp -f #{script} #{install_path}`
	end

	#############
	# MAN PAGES #
	#############
	if not File.executable?(which('man'))
		puts 'WARNING: `man` is not installed; manual pages cannot be installed.'
		puts 'Ensure that `man` is in your $PATH'
	else
		mandir = `man -w`.chomp.split(':')[-1]

		[mandir].each do |d|
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
		end
	end # if `man` is available
end
