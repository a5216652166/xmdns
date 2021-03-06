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
  # print "Initializing host list from xml..."
  xmlHostList = listFactory.getXMLHostList()
  hostList    = listFactory.getHostListFromXML(xmlHostList)
  # print "Initializing network list from xml..."
  xmlNetworkList = listFactory.getXMLNetworkList()
  networkList    = listFactory.getNetworkListFromXML(xmlNetworkList)
  # print "Initializing domain list from xml..."
  xmlDomainList = listFactory.getXMLDomainList()
  domainList    = listFactory.getDomainListFromXML(xmlDomainList)
  state       = xmldns.ProgState(hostList, networkList, domainList)
  state.setListFactory( listFactory )
  return state

################################################################################
# Generic functions to make life easier ########################################
################################################################################

################################################################################
# Save all changes #############################################################
################################################################################
# TODO: print out log of all changes generated by user

def saveChanges(state):
  '''Save the state of the host list to the xml file'''
  state.appendLogLiteral("Saved changes")
  state.getListFactory().writeXMLHostList(state)

################################################################################
# The main loop ################################################################
################################################################################

def usage(exit_status=None, error_text=None):
  print "Usage:"
  print "  " + sys.argv[0] + " --help"
  print "  " + sys.argv[0] + " --hostname hostname {OPTIONS}"
  print "OPTIONS:"
  print "  --replace"
  print "  --domain domain"
  print "  --a ip.v.4.address"
  print "  --aaaa ip:v:6::address"
  print "  --cname ip:v:6::address"
  print "  --mx '## full.name.of.host.'"
  print "  --description '...'"
  print "  --macAddress 00:11:22:33:44:55"
  if error_text is not None:
    print "Error: ", error_text
  if exit_status is not None:
    sys.exit(exit_status)

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

def fill_out_v6(ip):
   a=ip.split(':')
   if a.count('') == 2:
     a.remove('')
   try:
     empty_pos=a.index('')
   except ValueError:
     if len(a) == 8:
       return a
     raise
   replace = ['0' for n in range(9-len(a))]
   return a[0:empty_pos] + ['0' for n in range(9-len(a))] + a[empty_pos+1:]

def ipv6_in_net(ip, net, mask):
  matching_segments = len(range(0,mask,16))
  partial_bits = mask%16
  if partial_bits > 0:
    raise 'Need to code for a non-byte terminated IPv6 network mask: %s/%d' % (":".join(net), mask)
  return ip[0:matching_segments] == net[0:matching_segments]

def getNetworkFromIP6(state, ip):

  srcPieces = fill_out_v6(ip)

  for network in state.getNetworkList().getList():
    for prefix in network.getRecordsOfType('prefix'):
      ip_mask = prefix.recordData.split("/")
      ip_mask[1] = int(ip_mask[1])
      try:
        ipPieces = fill_out_v6(ip_mask[0])
        if ipv6_in_net(srcPieces, ipPieces, ip_mask[1]):
          return network.name
      except ValueError:
        pass
  # if we did not find a network, return nothing
  return None

def main(argv):

  # Set default domain for LPL
  new_host_args = {
    'domain': 'lpl.arizona.edu'
    }

  try:
    opts, args = getopt.getopt(argv, "", ['replace', 'help', 'hostname=', 'domain=', 'a=', 'aaaa=', 'cname=', 'mx=', 'description=', 'macAddress='])
    replace_records = False
  except getopt.GetoptError:
    usage(2)

  p_opts = [e for e,trash in opts]
  if not '--hostname' in p_opts and not '--help' in p_opts:
    print "Need one primary option"
    usage(2)

  # Initialize state from XML Document
  state = stateInit()

  # Parse in some arguments to keep track of record types we are dealing with
  for opt, arg in opts:
    opt = re.sub('^[-]+', '', opt)
    if opt in ( 'hostname', 'domain', 'a', 'aaaa', 'cname', 'mx', 'description', 'macAddress' ):
      new_host_args[ opt ] = arg
    if opt == 'replace':
      replace_records = True

  # Then look for an existing host entry that matches the same name
  filter = lambda host, input: host.shortname == new_host_args[ 'hostname' ] and host.domainname == input
  searchedHostList = state.getHostList().filteredList(filter,new_host_args[ 'domain' ])

  if len( searchedHostList.getList() ) > 0:
    print "Selecting existing host with same name/domain..."
    newHost = searchedHostList.getList()[0]
  else:
    # Let's create a host with the desired hostname/domain
    newHost = xmldns.XMLHost(new_host_args['domain'], new_host_args['hostname'])
    state.getHostList().addHost(newHost)

  # Set the current host
  state.setCurrentHost( newHost )

  dnsRecords = [ 'a', 'aaaa', 'cname', 'loc', 'mx', 'ns', 'ptr', 'rp', 'srv', 'txt' ]

  ## WE ARE HERE...
  # TODO: replace current record types with specified record types
  # DEBUG OUTPUT
  # state.getCurrentHost().printHost("| ")

  # Remove old records that we are replacing (or err on replace)
  for recordType in new_host_args.keys():
    filter = lambda rec: rec.recordType == recordType
    if recordType in dnsRecords:
      oldRecords = state.getCurrentHost().getDNSRecords( filter )
      for record in oldRecords:
        if not replace_records:
          usage(1, "Need to specify --replace to replace %s: %s" % (record.recordType, record.recordData))
        state.getCurrentHost().removeDNSRecord( record.recordType, record.recordData, record.recordNet )
        state.appendLog("Removed: %s [%s]: %s" % ( record.recordType, record.recordNet, record.recordData ))
    else:
      oldRecords, oldRecords2, oldRecords3 = state.getCurrentHost().getRecords( filter )
      for record in oldRecords:
        if not replace_records:
          usage(1, "Need to specify --replace to replace %s: %s" % (record.recordType, record.recordData))
        state.getCurrentHost().removeRecord( record.recordType, record.recordData )
        state.appendLog("Removed: %s: %s" % ( record.recordType, record.recordData ))
      for record in oldRecords2:
        if not replace_records:
          usage(1, "Need to specify --replace to replace %s: %s" % (record.recordType, record.recordData))
        state.getCurrentHost().removeRecord( record.recordType, record.recordData )
        state.appendLog("Removed: %s: %s" % ( record.recordType, record.recordData ))

  # initiate a record validator
  validator = xmldns.validator.RecordValidator( state )

  # Add records into host
  for opt, arg in opts:
    ## Remove -- from beginning of opt
    opt = re.sub('^[-]+', '', opt)

    if opt == 'replace':
      continue

    # Make sure record is syntactically valid
    if not validator.validRecord( opt, arg ):
      print "Error: " + arg + " is not a valid " + opt + " record."
      sys.exit(0)

    # Add the record (DNS or otherwise)
    if opt in dnsRecords:

      # 'a' records need to be placed in the correct network
      if opt == 'a':
        network = getNetworkFromIP4( state, arg )
        if not network:
          print "Error: IP does not belong to any registered network: %s" % arg
          sys.exit(-1)
        nets = [ network ]
      elif opt == 'aaaa':
        network = getNetworkFromIP6( state, arg )
        if not network:
          print "Error: IP does not belong to any registered network: %s" % arg
          sys.exit(-1)
        nets = [ network ]
      elif opt == 'cname':
        # Magic value!
        network = 'globalnet'
        if not network:
          print "Error: IP does not belong to any registered network: %s" % arg
          sys.exit(-1)
        nets = [ network ]
      else: # otherwise punt and add to all current networks
        nets = state.getCurrentHost().getNetworks()
        if len(nets) < 1:
          nets = ('globalnet')

      # Add record to all valid networks
      for net in nets:
        state.getCurrentHost().addDNSRecord( opt, arg, net )
        state.appendLog("Added: %s [%s]: %s" % (opt, net, arg))

    # Add a NON-DNS record (much easier)
    else:
      if opt not in ('hostname', 'domain'):
        state.getCurrentHost().addRecord( opt, arg )
        state.appendLog("Added: %s: %s" % (opt, arg))

  # Show new host description
  state.getCurrentHost().printHost("| ")

  # Save the configuration
  saveChanges( state )

  # Print session log
  print "Session Log:"
  print state.getLog()
  print "--------------------------------------------------------------------------------"

## What to do if we are called directly as an editor
if __name__ == "__main__":
  main(sys.argv[1:])
  sys.exit(0)
