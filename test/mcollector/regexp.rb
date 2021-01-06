#!/usr/bin/env ruby


require 'test/unit'
require_relative '../../mcollector.rb'

class TC_regexp < Test::Unit::TestCase

	def test_numReg
		strNumbers = [
			"06546",
			"-1657",
			"+654687",
			"-0546.4068",
			"+64764.1684",
			"6157.7687",
			"164.165e+154",
			"+16.468e-16",
			"-000.635e-1067",
			"1.16e+2",
			"0.3e-2",
			"1.4e+00",
			"1",
			"0",
		]

		strNumbers.each do |str|
			# here we add beginning and end to the regex
			# to check against the WHOLE string. Otherwise
			# "-.657" would match with "657"
			assert(str.match? /^#{$numReg}$/)
		end

		notStrNumbers = [
			"foo",
			".6876",
			"0684.",
			"+.674",
			"-.65767",
			".",
			"654.",
			".654",
			"+.6",
			"16a-67"
		]

		notStrNumbers.each do |str|
			# here we add beginning and end to the regex
			# to check against the WHOLE string. Otherwise
			# "-.657" would match with "657"
			assert(!str.match?(/^#{$numReg}$/))
		end
	end

	def test_quantityReg
		values = [
			"67",
			"+0610.6744e+676",
			"46547",
			"67.16E+77"
		]
		units = [
			"GB/s",
			"s",
			"Byte",
			"myunit"
		]
	values.zip(units).each_with_index do |pair,i|
			q = pair.join()
			reg = /^#{$quantityReg}$/
			assert(q.match?(reg))
			md = q.match(reg)
			assert(md.captures.length == 1)
			assert_equal(md.captures[0], pair[0]) # the capture group must match
			assert(pair[0].match?(reg)) # only the number must match too
		end
	end

	def test_quotationReg
		quotations = [
			'"fooo    bar	barz"',
			'"GTX 1070"',
			'"Lorem ipsum "'
		]

		quotations.each do |q|
			reg = /^#{$quotationReg}$/
			assert(q.match?(reg))
		end

		noQuotations = [
			'" uiae uie uiae ',
			'iaeuiae " uiae ',
			'uiaeuie"',
			'"uie"uiae"'
		]

		noQuotations.each do |nq|
			reg = /^#{$quotationReg}$/
			assert(!nq.match?(reg))
		end
	end

	def test_valReg
		strValues = [
			"06546",
			"-1657",
			"+654687",
			"-0546.4068",
			"+64764.1684",
			"6157.7687",
			"164.165e+154",
			"+16.468e-16",
			"-000.635e-1067",
			"1.16e+2",
			"0.3e-2",
			"1.4e+00",
			"1",
			"0",
			'"fooo    bar	barz"',
			'"GTX 1070"',
			'"Lorem ipsum "'
		]

		strValues.each do |v|
			assert(v.match?($valReg))
			md = v.match($valReg)
		end

		values = [
			"67",
			"+0610.6744e+676",
			"46547",
			"67.16E+77"
		]
		units = [
			"GB/s",
			"s",
			"Byte",
			"myunit"
		]

		values.zip(units).each_with_index do |pair,i|
			q = pair.join()
			#reg = /^#{$quantityReg}$/
			assert(q.match?($valReg))
			md = q.match($valReg)
			# now take the first non nil capture
			assert_equal(pair[0], md.captures.select { |c| c != nil}[0])
		end
	end

	def test_keyValueReg
		str = <<-eos
			uditra en Keyword0 = 1654GB/s uditae
			   \t uitae FooBar: "bar baz"
			   - other IMPORTANT    ---->   +61.65e-77Units uditar
			naed turl nedut rnle dtune dluvtr ned
			IMPORTANT but without link symbol
			 SomeInt = 465768 
			 TakeWithUnits = "9981MEGAUNIT"
			   again but not recognized FooBar: "nope"
			   someK   ==>  00.1234
		eos

		check = ->(key, expectedValue) {
			md = str.match(getKeyValueReg(:keyword => key))
			assert_equal(expectedValue, md["value"])
		}

		key2val = {
			"Keyword0" => "1654",
			"FooBar" => '"bar baz"',
			"IMPORTANT" => "+61.65e-77",
			"SomeInt" => "465768",
			"TakeWithUnits" => '"9981MEGAUNIT"',
			"someK" => "00.1234",
		}

		key2val.each_pair do |key, val|
			check.call(key, val)
		end

	end

	def test_csvReg

	csvstr = <<-eos
	iaueuiae
	u
	iae
	uieuiaeuieeiuaei

foo,bar,baz,"long name"
1,2,3,"foo bar"
4,5,6,"bar bazu"

uia
eiuaeuia
e

	eos

	csvpart = <<-eos
foo,bar,baz,"long name"
1,2,3,"foo bar"
4,5,6,"bar bazu"
eos

	md = $csvReg.match(csvstr)
	assert_equal(csvpart, md[0])

	end

	def test_csvReg2

	csvstr = <<-eos

==4193== NVPROF is profiling process 4193, command: ./build/release/bench -N 16777216 --M 31 --final-stage-solver gpu --num-warmups 200 --num-measurements 1 --pivoting true --N-last-stage 32

# Tridigpu Benchmark Application

  - device = "GeForce GTX 1070"
  - num_warmups = 200
  - num_measurements = 1
  - block_dim_phaseone = 256
  - block_dim_phasetwo = 256
  - M = 31
  - num_sthreads_block = 32
  - N_last_stage = 32
  - final_stage = gpu
  - pivoting = true
  - epsilon = 0
  - phaseone_parallel = true
  - num_redundant_kernel_executions = 1
  - matrix_path = 
  - N = 16777216
  - matrix_init_scheme = model1
  - read_permutation_init_scheme = none
  - write_permutation_init_scheme = none
  - solver = tridigpu
==4193== Some kernel(s) will be replayed on device 0 in order to collect all events/metrics.
  - stage_sizes = [16777216, 1082402, 69834, 4506, 292, 20, ]

## Throughputs of the first stages of phase one and phase two

`num_measurements` measurements were taken and the mean time is taken for throughput calculation

  - phaseone-0-copy-kernel-equivalent-throughput = 201.586
  - phaseone-0-copy-kernel-equivalent-time = 0.00133162
  - phaseone-0-memcopy-kernel-equivalent-throughput = 196.856
  - phaseone-0-memcopy-kernel-equivalent-time = 0.00136362
  - equation_throughput = 37.6037 MRows/s
==4193== Profiling application: ./build/release/bench -N 16777216 --M 31 --final-stage-solver gpu --num-warmups 200 --num-measurements 1 --pivoting true --N-last-stage 32
==4193== Profiling result:
==4193== Metric result:
"Device","Kernel","Invocations","Metric Name","Metric Description","Min","Max","Avg"
"GeForce GTX 1070 (0)","void tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>(thrust::zip_iterator<tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>::generate_tuple_type<float const *, unsigned int=1>::type>, float const *, float const *, float const *, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, thrust<thrust::zip_iterator<float*, unsigned int=1>::type>, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, int const *, int const , __int64, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, float)",5,"gld_throughput","Global Load Throughput",715.782047MB/s,159.183110GB/s,154.670076GB/s
"GeForce GTX 1070 (0)","void tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>(thrust::zip_iterator<tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>::generate_tuple_type<float const *, unsigned int=1>::type>, float const *, float const *, float const *, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, thrust<thrust::zip_iterator<float*, unsigned int=1>::type>, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, int const *, int const , __int64, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, float)",5,"gst_throughput","Global Store Throughput",193.682200MB/s,41.122196GB/s,37.989150GB/s

	eos

	csvpart = <<-eos
"Device","Kernel","Invocations","Metric Name","Metric Description","Min","Max","Avg"
"GeForce GTX 1070 (0)","void tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>(thrust::zip_iterator<tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>::generate_tuple_type<float const *, unsigned int=1>::type>, float const *, float const *, float const *, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, thrust<thrust::zip_iterator<float*, unsigned int=1>::type>, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, int const *, int const , __int64, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, float)",5,"gld_throughput","Global Load Throughput",715.782047MB/s,159.183110GB/s,154.670076GB/s
"GeForce GTX 1070 (0)","void tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>(thrust::zip_iterator<tridigpu::phasetwo_kernel<unsigned int=31, unsigned int=256, unsigned int=32, unsigned int=1, __int64, float, float, float, float, float const , float, float const , float const , float, float, float, float, float, bool=0, bool=0, bool=0>::generate_tuple_type<float const *, unsigned int=1>::type>, float const *, float const *, float const *, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, thrust<thrust::zip_iterator<float*, unsigned int=1>::type>, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, int const *, int const , __int64, thrust<thrust::zip_iterator<float const *, unsigned int=1>::type>, float)",5,"gst_throughput","Global Store Throughput",193.682200MB/s,41.122196GB/s,37.989150GB/s
eos

	md = $csvReg.match(csvstr)
	assert_equal(csvpart, md[0])

	end

end
