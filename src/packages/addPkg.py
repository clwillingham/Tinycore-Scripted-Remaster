#! /usr/bin/env python
import sys
import urllib2
import os
import os.path

#print sys.argv[0] # prints the filename of your script
#print sys.argv[1] # and the first parameter
#print sys.argv[1:] # or all parameters

PKGDIR = "http://distro.ibiblio.org/tinycorelinux/4.x/x86/tcz/"

alldeps = []

def getDeps(pkg=""):
	try: response = urllib2.urlopen(PKGDIR + pkg + ".dep")
	except urllib2.HTTPError, e:
		print "no deps"
		return ['']

	deps = response.read().split('\n')
	for dep in deps:
		if len(dep) > 0 and dep != ' ':
			print dep
			if dep not in alldeps:
				alldeps.append(dep)
				getDeps(dep)
	
	
	return deps

def downloadPkg(pkg=""):
	print "downloading: " + pkg
	if not os.path.isfile(pkg):
		os.system("wget " + PKGDIR + pkg)
	else:
		print "\t file already downloaded"

	getDeps(pkg)
	#print alldeps.length + " Depencencies need to be downloaded"
	for dep in alldeps:
		if not os.path.isfile(dep):
			os.system("wget " + PKGDIR + dep)
		else:
			print "\t" + dep + " already downloaded"
	
	
downloadPkg(sys.argv[1])



