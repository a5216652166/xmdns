#!/usr/bin/env python

import warnings
warnings.filterwarnings("ignore", category=FutureWarning, append=1)

import xmldns
import xmldns.validator
import sys
import getopt
import os
import re

# Really, this should have been a class with the state available as instance
# variables but I guess I am still thinking like a c programmer
def stateInit():
  ''' Initializes/returns the state object '''
  # doc_base = "../../res/db/"
  doc_base = "res/db/"
  listFactory = xmldns.ListFactory(doc_base)
  xmlHostList = listFactory.getXMLHostList()
  hostList    = listFactory.getHostListFromXML(xmlHostList)
  xmlNetworkList = listFactory.getXMLNetworkList()
  networkList    = listFactory.getNetworkListFromXML(xmlNetworkList)
  xmlDomainList = listFactory.getXMLDomainList()
  domainList    = listFactory.getDomainListFromXML(xmlDomainList)
  state       = xmldns.ProgState(hostList, networkList, domainList)
  state.setListFactory( listFactory )
  return state

def getNetworkFromIP4(state, ip):

  # Make quad easy to work with
  prefixSplit = re.compile(r'^(\d+)\.(\d+)\.(\d+)\.(\d+)/(\d+)$')
  srcPieces = ip.split(".")
  srcNum = 0
  srcNum += int(srcPieces[0]) << 24
  srcNum += int(srcPieces[1]) << 16
  srcNum += int(srcPieces[2]) << 8
  srcNum += int(srcPieces[3])

  for network in state.getNetworkList().getList():
    for prefix in network.getRecordsOfType('prefix'):
      if re.match("^\d+\.\d+\.\d+\.\d+/\d+$", prefix.recordData):
        ipPieces = prefixSplit.search( prefix.recordData ).groups()
        prefixNum = 0
        prefixNum += int(ipPieces[0]) << 24
        prefixNum += int(ipPieces[1]) << 16
        prefixNum += int(ipPieces[2]) << 8
        prefixNum += int(ipPieces[3])
        prefixMask = 0;
        for i in range(int(ipPieces[4])):
          prefixMask = prefixMask << 1
          prefixMask = prefixMask + 1
        for i in range(32 - int(ipPieces[4])):
          prefixMask = prefixMask << 1
        # print "prefix/mask: %d/%d" % (prefixNum, prefixMask)
        tmp1 = srcNum & prefixMask
        tmp2 = prefixNum & prefixMask
        # If the IP is in the network prefix... return the network
        if tmp1 == tmp2:
          return network.name
  # if we did not find a network, return nothing
  return None

def findFreeIPInNet(state, networkName, verbose = 0):
  ''' verbose prints all IPs up to the first free IP found '''

  filter = lambda rec: rec.recordType == 'a' and rec.recordNet == networkName
  netRecords = state.getHostList().getDNSRecords( filter )
  network = state.getNetworkList().getNetwork( networkName )
  prefices = network.getRecordsOfType( 'prefix' )

  ret = []
  ## Really Ugly... oh well
  for prefix in prefices:
    if re.match("^\d+\.\d+\.\d+\.\d+/24$", prefix.recordData):
      ipPieces = prefix.recordData.split(".")
      foundCount = 0
      # iterate through IP's
      for num in range(1,255):
        freeIP = "%s.%s.%s.%d" % (ipPieces[0], ipPieces[1], ipPieces[2], num)
        found = 0
        # Iterate through records (should really just be a hash)
        for record in netRecords:
          if record.recordData == freeIP:
            found = 1
            if verbose and len(ret) < 1:
              print "%s: %s" % ( freeIP, "in use" )
        if not found:
          ret.append( freeIP )
  # ret.sort()
  return ret

def usage():
  print '''Usage:
  find_open_ip.py [-vh] [-c max_num] -s IP-portion
Examples:
  Find an open IP in the 108 network
  % find_open_ip.py -s 150.135.108

  Find up to 10 open IPs on the 110 network
  % find_open_ip.py -c 10 -s 150.135.110

  Find open IPs on the 110 network and print
  all scanned IPs up to the first free IP
  % find_open_ip.py -v -c 10 -s 150.135.110

  Find open IPs on the 100 network and print
  the hex equivalent (useful for IPv6)
  % find_open_ip.py -v --hex -c 10 -s 150.135.110
'''

def main(argv):
  state = stateInit()

  progOpts = {
    'verbose': 0,
    'search': None,
    'count': 1
  }

  opts, args = getopt.getopt(argv, "6hvs:c:", [ "hex", "help", "verbose", "search=", "count" ])
  progOpts['hex'] = False

  for opt, arg in opts:
    opt = re.sub('^[-]+', '', opt)
    if opt in ['v', 'verbose']:
      progOpts['verbose'] = 1
    elif opt in ['s', 'search']:
      progOpts['search'] = arg
    elif opt in ['c', 'count']:
      progOpts['count'] = int(arg)
    elif opt in ['6', 'count']:
      progOpts['hex'] = True
    elif opt in ['h', 'help']:
      usage()
      sys.exit(0)

  if not progOpts['search']:
    usage()
    sys.exit(0)

  ## We need to know when to ask for a network...
  networkName = None
  ipPieces = progOpts['search'].split(".")
  for i in range(4-len(ipPieces)):
    ipPieces.append("0")
  fullIP = ".".join(ipPieces)
  networkName = getNetworkFromIP4(state, fullIP)
  ret = []
  if networkName:
    ret = findFreeIPInNet(state, networkName, progOpts['verbose'])

  if len(ret) < 1:
    print "No free IPs detected in range"
    sys.exit(0)

  if progOpts['count'] > len(ret):
    progOpts['count'] = len(ret)

  if progOpts['hex']:
    ## A little gross, oh well
    for i in range(progOpts['count']):
      output = ret[i].split(".")
      print "%15s - %.2x%.2x %.2x%.2x" % (
         ret[i],
         int(output[0]),
         int(output[1]),
         int(output[2]),
         int(output[3]))
  else:
    for i in range(progOpts['count']):
      print ret[i]


## What to do if we are called directly as an editor
if __name__ == "__main__":
  main(sys.argv[1:])
  sys.exit(0)
