require 'fileutils'

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

task :install, [:install_d,:man_d] => [:default] do |task,args|
    args.with_defaults(:install_d => "/usr/local/bin",
                       :man_d => `man -w`.chomp.split(':')[-1]
                      )
	install_d = File.expand_path(args.install_d)
	mandir = File.expand_path(args.man_d)

    puts "Installing ruby scripts to #{install_d}"
    puts "Installing man files to #{mandir}"

    # Ensure the required folders are available
    FileUtils.mkdir_p install_d
    FileUtils.mkdir_p mandir

	[install_d, mandir].each do |d|
		if !File.directory?(d)
			puts "ERROR: directory #{d} does not exist"
			exit 1
		end
		if !File.writable?(d)
			puts "ERROR: you have no permissions to write at #{d}"
			exit 1
		end
	end

	# INSTALL MAN PAGES
	targets.map do |t|
		manf = File.expand_path("build/#{t}.1.gz")
		man1dir = "#{mandir}/man1/"
        FileUtils.mkdir_p man1dir
		install_path = man1dir + File.basename(manf)
		`cp -f #{manf} #{install_path}`
	end

	# INSTALL SCRIPTS
	install_files = [
		"math.rb",
		"regular-expressions.rb",
		"minstructor.rb",
		"version.rb"
		"mcollector.rb",
		"mcollector-modules/akav.rb",
		"mcollector-modules/kav.rb",
		"mcollector-modules/base.rb",
		"mcollector-modules/available-modules.rb",
	]
	libpath = install_d + "/minstructor-lib/"
	install_files.each do |f|
		install_path = libpath + f
		puts "install _path = #{install_path}"
		if !File.directory?(File.dirname(install_path))
			FileUtils.mkdir_p(File.dirname(install_path))
		end
		FileUtils.copy(f, install_path)
	end

	# INSTALL SOFTLINKS FOR EXECUTION
	targets.each do |t|
		FileUtils.ln_s(libpath + t + ".rb", install_d + "/#{t}", force: true)
	end
end
