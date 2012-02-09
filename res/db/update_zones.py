#!/usr/bin/env python

# Let's use a process pool to more efficiently process the bind zone data...
# this makes sense since it's all just character parsing and we have a lot of
# cores on machines we are running the update on.
import multiprocessing

# Let's use subprocess to help easily migrate away from the old script
from subprocess import call,check_call,check_output

# Because we need to run stuff and know what day it is
import sys,os,datetime

# Because we are lazy
import glob,re

# Quick checks to help insure sanity ...
class xslCheck:
	def __init__(self, desc, command, check_type='clean_exit', check_params={}):
		self.desc = desc
		self.command = command
		self.check_type = check_type
		self.check_params = check_params

	def run(self):
		return {
			'clean_exit': self.run_clean_exit,
			'contains_valid_lines': self.run_contains_valid_lines,
			'contains_valid_words': self.run_contains_valid_words,
			'no_output':  self.run_no_output,
			'uniq_lines': self.run_uniq_lines,
			'uniq_first_words': self.run_uniq_first_words,
		}[ self.check_type ]()

	def run_clean_exit(self):
		''' run the test and check for non-zero status '''
		retcode = call(self.command.split())
		if retcode == 0:
			print "pass: ", self.desc
		else:
			print "fail: ", self.desc
		return retcode

	def run_contains_valid_lines(self):
		''' run the test and check for uniq lines '''
		lines = check_output(self.command.split()).split("\n")
		uniq_lines = set(lines)

		params = self.check_params

		check_passed = False

		valid_lines = set(params['valid_lines'])

		invalid_lines = uniq_lines.difference(valid_lines)
		if len(invalid_lines) > 0:
			print "fail: ", self.desc
			for line in invalid_lines:
				print "invalid content: ", line
			return -1

		print "pass: ", self.desc
		return 0

	def run_contains_valid_words(self):
		''' run the test and check for valid words in each line'''
		lines = check_output(self.command.split()).split("\n")
		uniq_lines = set(lines)

		params = self.check_params
		valid_words = set(params['valid_words'])

		def valid_line(line):
			for word in line.split():
				if word in valid_words:
					return True
			print "line: ", line
			print "len(line): ", len(line)

			print "Valid words: ", valid_words
			sys.exit(0)
			return False

		invalid_lines = [line for line in uniq_lines if len(line)>0 and not valid_line(line)]
		if len(invalid_lines) > 0:
			print "fail: ", self.desc
			for line in invalid_lines:
				print "invalid content: ", line
			return -1

		print "pass: ", self.desc
		return 0

	def run_uniq_first_words(self):
		''' run the test and check for uniq first words'''
		lines = check_output(self.command.split()).split("\n")

		def first_word(line):
			try:
				return line.split()[0]
			except IndexError:
				return None

		first_words = map(first_word, lines)
		uniq_first_words = set(first_words)

		if len(uniq_first_words) == len(first_words):
			print "pass: ", self.desc
			return 0

		print "fail: ", self.desc
		for n in uniq_first_words:
			first_words.remove(n)
		print "duplicate entries: ", first_words
		return -1

	def run_no_output(self):
		''' run the test and check for output '''
		output = check_output(self.command.split())
		if len(output) == 0:
			print "pass: ", self.desc
			return 0

		print "fail: ", self.desc
		return -1

	def run_uniq_lines(self):
		''' run the test and check for uniq lines '''
		lines = check_output(self.command.split()).split("\n")
		uniq_lines = set(lines)
		if len(uniq_lines) == len(lines):
			print "pass: ", self.desc
			return 0

		for n in uniq_lines:
			lines.remove(n)

		print "fail: ", self.desc
		print "duplicate entries: ", lines
		return -1

domain_list_cmd = 'xsltproc --novalid tools/domainnames_from_domain_list.xsl domain_list.xml'.split()
domain_list = check_output(domain_list_cmd)
domain_list = [ domain for domain in domain_list.split("\n") if len(domain) > 1 ]

print "Domain list: ",domain_list

checks = [
	xslCheck(
		"domain_list.xml syntax",
		"xmllint --noblanks --valid domain_list.xml --noout",
		),
	xslCheck(
		"host_list.xml syntax",
		"xmllint --noblanks --valid host_list.xml --noout",
		),
	xslCheck(
		"net_list.xml syntax",
		"xmllint --noblanks net_list.xml --noout",
		),

	xslCheck(
		"duplicate hostnames/entries",
		"xsltproc --novalid tools/hostnames.xsl host_list.xml",
		'uniq_lines',
		),

	xslCheck(
		"hostname=shortname.domainname",
		"xsltproc --novalid tests/short_domain_hostname.xsl host_list.xml",
		'no_output',
		),

	xslCheck(
		"unregistered domains",
	 	"xsltproc --novalid tools/domainnames_from_host_list.xsl host_list.xml",
		'contains_valid_words',
		{'valid_words': domain_list}
		),

	xslCheck(
		"duplicate mac address",
		"xsltproc --novalid tools/mac_addresses.xsl host_list.xml",
		'uniq_first_words',
		),
	]

for check in checks:
	if check.run():
		sys.exit(-1)

# TODO: incorporate TZ info into this
now = datetime.datetime.now()
serial_date = now.strftime("%Y%m%d%H")

def xsltproc(xsl_params, xsl_file, xml_file, output_file):
	xsltproc_cmd = ['xsltproc', '--novalid']
	for key in xsl_params.keys():
		xsltproc_cmd.extend(['--stringparam', key, xsl_params[key]])
	xsltproc_cmd.extend([xsl_file, xml_file])
	try:
		content = check_output(xsltproc_cmd)
	except CalledProcessError:
		print "Failed to generate output from ", xsltproc_cmd
		raise
	open(output_file, 'w').write( content )
	print ".",

files = glob.glob("forward-zones/*.xsl")
forward_zones_re = re.compile('forward-zones/(.+).xsl')
forward_zones = map(forward_zones_re.match, files)

jobs = []

print "Generating zone data."
for match_obj in forward_zones:
	forward_view = match_obj.group(1)
	p = multiprocessing.Process(target=xsltproc, args=(
		{'target_view': forward_view},
		'tools/views_named_conf.xsl',
		'domain_list.xml',
		'../../views/%s/named.conf' % forward_view
		)
		)
	jobs.append(p)
	p.start()

	# touch the file to ensure that it exists.
	extra_reverse = "../../views/%s/extra-reverse.conf" % forward_view
	if not os.path.exists(extra_reverse):
		open(extra_reverse,"a+").close()

	for domain in domain_list:
		short_name = domain.split(".")[0]
		p = multiprocessing.Process(target=xsltproc, args=(
			{
			'target_domain': domain,
			'target_view': forward_view,
			'target_serial': serial_date,
			},
			'xsl-res/soa.xsl',
			'domain_list.xml',
			'../../views/%s/headers/db-%s' % (forward_view, domain)
			)
			)
		jobs.append(p)
		p.start()

		p = multiprocessing.Process(target=xsltproc, args=(
			{
			'target_domain': domain,
			},
			'forward-zones/%s.xsl' % forward_view,
			'host_list.xml',
			'../../views/%s/zones/db-%s' % (forward_view, domain)
			)
			)
		jobs.append(p)
		p.start()

files = glob.glob("reverse-zones/*.xsl")
reverse_zones_re = re.compile('reverse-zones/(ipv[46])-(.+).xsl')
reverse_zones = map(reverse_zones_re.match, files)

jobs = []

for match_obj in reverse_zones:
	ipv46 = match_obj.group(1)
	reverse_view = match_obj.group(2)
	# Generate reverse ip headers
	p = multiprocessing.Process(target=xsltproc, args=(
		{
		'target_network': reverse_view,
		'target_proto': ipv46,
		},
		'xsl-res/rev-soa.xsl',
		'net_list.xml',
		'../../reverse/headers/%s-%s' % (ipv46, reverse_view)
		)
		)
	jobs.append(p)
	p.start()

	# Generate reverse ip lookup tables
	p = multiprocessing.Process(target=xsltproc, args=(
		{},
		'reverse-zones/%s-%s.xsl' % (ipv46, reverse_view),
		'host_list.xml',
		'../../reverse/zones/%s-%s' % (ipv46, reverse_view)
		)
		)
	jobs.append(p)
	p.start()

# Process host documentation
p = multiprocessing.Process(target=call, args=(["../../Docs/views/xslt/generate_dbs"]))
jobs.append(p)
p.start()

# Process dhcp tables
p = multiprocessing.Process(target=call, args=(["../../dhcp_area/xslt/generate_dbs"]))
jobs.append(p)
p.start()

