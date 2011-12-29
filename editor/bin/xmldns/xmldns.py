#!/usr/bin/env python
"""An interface to managing hosts via an xml list
"""

import xml.dom.minidom
import string
import re

# TODO: create network lists, and domain lists (as well as supporting classes)

## Feeling lazy, this is basically just XMLHostList with s/host/domain/ and s/Host/Domain/
class XMLDomainList:

  def __init__(self):
    '''Initialize an empty list'''
    self.__domainList = []

  def seedDomainsFromXML(self, xmlData):
    for topNode in xmlData.childNodes:
      for node in topNode.childNodes:
        if node.nodeType == node.ELEMENT_NODE:
          if node.localName == 'domain':
            self.addDomainFromXML(node)
          else:
            print "Skipping node:", node

  ''' given an xml description (xmlNode) of a single domain, create a domain object '''
  def addDomainFromXML(self, xmlNode):
    domain = xmlNode.childNodes[0].childNodes[0]
    # print "Domain: " + domain.wholeText
    newDomain = XMLDomain(domain.wholeText)
    for node in xmlNode.childNodes[1:]:
      if node.nodeType != node.ELEMENT_NODE:
        continue
      newDomain.addRecord(node.localName, node.childNodes[0].wholeText)
    self.__domainList.append(newDomain)

  def getList(self):
    return self.__domainList

  def filteredList(self, filter, filterInput):
    '''filteredList(self, filter, filterInput) -> XMLDomainList

    filter is a lambda in the form of:
      lambda domain, input: domain.SomeFunction(input)  OR
      lambda domain, input: domain.someProperty == input OR ...
    filterInput is passed to the filter and the filter is run as:
      if( filter(domain, filterInput) )
        ... add domain to filtered list ...
    '''
    filteredList = XMLDomainList()
    for domains in self.__domainList:
      if filter(domains, filterInput):
        filteredList.addDomain(domains)
    return filteredList

  def addDomain(self, newDomain):
    ''' given an XMLDomain instance add it to the list of domains'''
    self.__domainList.append(newDomain)

  def removeDomain(self, oldDomain):
    ''' given an XMLDomain instance remove it from the list of domains'''
    self.__domainList.remove(oldDomain)

  # '''returns an xml (string) representation of the domainList object'''
  # TODO: make this more efficient in conjunction with XMLDomain.dumpXML()
  def dumpXML(self):
    ret = ""
    ret += '<?xml version="1.0" standalone="yes"?>'+"\n"
    ret += '<!DOCTYPE domain_list SYSTEM "domain_list.dtd">'+"\n"
    ret += "<domain_list>\n"
    for domain in self.__domainList:
      ret += domain.dumpXML()
    ret += "</domain_list>\n"
    return ret

## Feeling lazy, this is basically just XMLDomainList
class XMLNetworkList:

  def __init__(self):
    '''Initialize an empty list'''
    self.__networkList = []

  def seedNetworksFromXML(self, xmlData):
    for topNode in xmlData.childNodes:
      for node in topNode.childNodes:
        if node.nodeType == node.ELEMENT_NODE:
          if node.localName == 'network':
            self.addNetworkFromXML(node)
          else:
            print "Skipping node:", node

  ''' given an xml description (xmlNode) of a single network, create a network object '''
  def addNetworkFromXML(self, xmlNode):
    network = xmlNode.childNodes[0].childNodes[0]
    recursion = xmlNode.attributes['recursion'].value
    type = xmlNode.attributes['type'].value
    # print "Network: " + network.wholeText
    newNetwork = XMLNetwork(network.wholeText, recursion, type)
    for node in xmlNode.childNodes[1:]:
      if node.nodeType != node.ELEMENT_NODE:
        continue
      if len(node.childNodes) > 0:
        newNetwork.addRecord(node.localName, node.childNodes[0].wholeText)
      else:
        newNetwork.addRecord(node.localName, None)
    self.__networkList.append(newNetwork)

  def getList(self):
    return self.__networkList

  def getNetwork(self, networkName):
    ''' Get network by name '''
    for net in self.__networkList:
      if net.name == networkName:
        return net
    return None

  def filteredList(self, filter, filterInput):
    '''filteredList(self, filter, filterInput) -> XMLNetworkList

    filter is a lambda in the form of:
      lambda network, input: network.SomeFunction(input)  OR
      lambda network, input: network.someProperty == input OR ...
    filterInput is passed to the filter and the filter is run as:
      if( filter(network, filterInput) )
        ... add network to filtered list ...
    '''
    filteredList = XMLNetworkList()
    for networks in self.__networkList:
      if filter(networks, filterInput):
        filteredList.addNetwork(networks)
    return filteredList

  def addNetwork(self, newNetwork):
    ''' given an XMLNetwork instance add it to the list of networks'''
    self.__networkList.append(newNetwork)

  def removeNetwork(self, oldNetwork):
    ''' given an XMLNetwork instance remove it from the list of networks'''
    self.__networkList.remove(oldNetwork)

  # '''returns an xml (string) representation of the networkList object'''
  # TODO: make this more efficient in conjunction with XMLNetwork.dumpXML()
  def dumpXML(self):
    ret = ""
    ret += '<?xml version="1.0" standalone="yes"?>'+"\n"
    ret += '<!DOCTYPE network_list SYSTEM "network_list.dtd">'+"\n"
    ret += "<network_list>\n"
    for network in self.__networkList:
      ret += network.dumpXML()
    ret += "</network_list>\n"
    return ret

class XMLHostList:

  def __init__(self):
    '''Initialize an empty list'''
    self.__hostList = []

  def seedHostsFromXML(self, xmlData):
    for topNode in xmlData.childNodes:
      for node in topNode.childNodes:
        if node.nodeType == node.ELEMENT_NODE:
          if node.localName == 'host':
            self.addHostFromXML(node)
          else:
            print "Skipping node:", node

  ''' given an xml description (xmlNode) of a single host, create a host object '''
  def addHostFromXML(self, xmlNode):
    shortname = xmlNode.childNodes[1].childNodes[0]
    domain = xmlNode.childNodes[2].childNodes[0]
    # print "Host: " + shortname.wholeText + "." + domain.wholeText
    newHost = XMLHost(domain.wholeText, shortname.wholeText)
    for node in xmlNode.childNodes[3:]:
      if node.nodeType != node.ELEMENT_NODE:
        continue
      if "net" in node.attributes.keys() :
        # if node.localName == 'a':
        # print "NET: " + node.localName
        ttl = None
        if "ttl" in node.attributes.keys():
          ttl = node.attributes["ttl"].value
        newHost.addDNSRecord(
        	node.localName,
        	node.childNodes[0].wholeText,
        	node.attributes["net"].value,
        	ttl
        	)
      else:
        # print "NO NET: " + node.localName
        if node.childNodes:
          newHost.addRecord(node.localName, node.childNodes[0].wholeText)
    self.__hostList.append(newHost)

  def getList(self):
    return self.__hostList

  def filteredList(self, filter, filterInput):
    '''filteredList(self, filter, filterInput) -> XMLHostList

    filter is a lambda in the form of:
      lambda host, input: host.SomeFunction(input)  OR
      lambda host, input: host.someProperty == input OR ...
    filterInput is passed to the filter and the filter is run as:
      if( filter(host, filterInput) )
        ... add host to filtered list ...
    '''
    filteredList = XMLHostList()
    for hosts in self.__hostList:
      if filter(hosts, filterInput):
        filteredList.addHost(hosts)
    return filteredList

  def addHost(self, newHost):
    ''' given an XMLHost instance add it to the list of hosts'''
    self.__hostList.append(newHost)

  def removeHost(self, oldHost):
    ''' given an XMLHost instance remove it from the list of hosts'''
    self.__hostList.remove(oldHost)

  def getDNSRecords(self, filter):
    ''' given an XMLHost instance return a filtered list of dns records'''
    ret = []
    for host in self.__hostList:
      ret.extend( host.getDNSRecords( filter ) )
    ret.sort()
    return ret

  # '''returns an xml (string) representation of the hostList object'''
  # TODO: make this more efficient in conjunction with XMLHost.dumpXML()
  def dumpXML(self):
    ret = ""
    ret += '<?xml version="1.0" standalone="yes"?>'+"\n"
    ret += '<!DOCTYPE host_list SYSTEM "host_list.dtd">'+"\n"
    ret += "<host_list>\n"
    for host in self.__hostList:
      ret += host.dumpXML()
    ret += "</host_list>\n"
    return ret

## Feeling lazy, this is basically just XMLHost with s/host/domain/ and s/Host/Domain/
class XMLDomain:

  def __init__(self, domain):
    # print "Initialized XMLHost:", shortname + "." + domain
    self.name = domain
    self.__records = RecordList()

  def addRecord(self, recordType, recordData):
    """ addRecord(XMLDomain, string, string) - adds a record (description/notes...)

    """
    return self.__records.add(recordType, recordData)

  def removeRecord(self, recordType, recordData):
    return self.__records.remove(recordType, recordData)

  def printDomain(self, prefix=""):
    """ printDomain(XMLDomain) - prints a human readable output of an XMLDomain object 

    """
    print prefix + "Domain: " + self.name
    for record in self.__records.getRecords():
      print prefix + record.recordType + ": " + record.recordData
    print prefix + "--------------------------------------------------------------------------------"

  def getRecordsOfType(self, recordType):
    """ getRecordsOfType(recordType) - returns list of records of the specified type

    """
    ret = []
    for record in self.__records.getRecords():
      if( record.recordType == recordType ):
        ret.append( record )
    return ret

  # returns an xml (string) representation of the host object
  def dumpXML(self):
    ret = ""
    ret += "  <domain>\n"
    ret += "    <name>" + self.name + "</name>\n"
    for record in self.__records.getRecords():
      ret += "    <" + record.recordType + '>' + record.recordData + '</' + record.recordType + '>' + "\n"
    ret += "  </domain>\n" 
    return ret

  def containsRecordType(self, recordType):
    '''containsRecordType(self, recordType) -> 0/1 (false/true)

    determines if any record of recordType is stored in this domain entry
    '''
    for record in self.__records.getRecords():
      if record.recordType == recordType:
        return 1
    return 0

## Feeling lazy, this is basically just XMLDomain
class XMLNetwork:

  def __init__(self, network, recursion, type):
    self.name = network
    self.recursion = recursion
    self.type = type
    self.__records = RecordList()

  def addRecord(self, recordType, recordData):
    """ addRecord(XMLNetwork, string, string) - adds a record (description/notes...)

    """
    return self.__records.add(recordType, recordData)

  def removeRecord(self, recordType, recordData):
    return self.__records.remove(recordType, recordData)

  def printNetwork(self, prefix=""):
    """ printNetwork(XMLNetwork) - prints a human readable output of an XMLNetwork object 

    """
    print prefix + "Network: " + self.name
    for record in self.__records.getRecords():
      print prefix + record.recordType + ": " + record.recordData
    print prefix + "--------------------------------------------------------------------------------"

  # returns an xml (string) representation of the host object
  def dumpXML(self):
    ret = ""
    ret += "  <network>\n"
    ret += "    <name>" + self.name + "</name>\n"
    for record in self.__records.getRecords():
      ret += "    <" + record.recordType + '>' + record.recordData + '</' + record.recordType + '>' + "\n"
    ret += "  </network>\n" 
    return ret

  def getRecordsOfType(self, recordType):
    """ getRecordsOfType(recordType) - returns list of records of the specified type

    """
    ret = []
    for record in self.__records.getRecords():
      if( record.recordType == recordType ):
        ret.append( record )
    return ret

  def containsRecordType(self, recordType):
    '''containsRecordType(self, recordType) -> 0/1 (false/true)

    determines if any record of recordType is stored in this domain entry
    '''
    for record in self.__records.getRecords():
      if record.recordType == recordType:
        return 1
    return 0

  def __str__( self ):
    ret = "Network: " + self.name + "\n"
    for record in self.__records.getRecords():
      if record.recordData:
        ret += record.recordType + ": " + record.recordData + "\n"
      else:
        ret += record.recordType + "\n"
    ret += "--------------------------------------------------------------------------------\n"
    return ret

class XMLHost:

  def __init__(self, domain, shortname):
    # print "Initialized XMLHost:", shortname + "." + domain
    self.domainname = domain
    self.shortname  = shortname
    self.__dnsRecords = DNSRecordList()
    self.__otherRecords = RecordList()

  def addRecord(self, recordType, recordData):
    """ addRecord(XMLHost, string, string) - adds a non-DNS record (action/description/macAddress/notes...)

    """
    # normalize all mac addresses for ease of comparison/search/...
    if recordType == 'macAddress':
      recordData = self.expandMac(recordData)
    return self.__otherRecords.add(recordType, recordData)

  def removeRecord(self, recordType, recordData):
    return self.__otherRecords.remove(recordType, recordData)

  def addDNSRecord(self, recordType, recordData, recordNet, recordTTL = None):
    """ addDNSRecord(XMLHost, string, string, string) - adds a DNS record (a/aaaa/loc/mx...)

    """
    return self.__dnsRecords.add(recordType, recordData, recordNet, recordTTL)

  def removeDNSRecord(self, recordType, recordData, recordNet):
    ''' getRecords(self) -> ( dnsRecords, otherRecords )
    '''
    return self.__dnsRecords.remove(recordType, recordData, recordNet)

  def getRecords(self, filter = lambda record: 1):
    ''' getRecords(self) -> ( dnsRecords, otherRecords )
       filter is a lambda that is passed the record attribute:
       lambda rec: rec.recordType == 'hostname'
    '''
    ret1 = []
    ret2 = []
    for record in self.__dnsRecords.getRecords():
      if filter( record ):
        ret1.append( record )
    for record in self.__otherRecords.getRecords():
      if filter( record ):
        ret2.append( record )
    ret = (ret1, ret2)
    return ret

  def getDNSRecords(self, filter = lambda record: 1):
    ''' getDNSRecords(self, filter) -> [ records ] '''
    ret = []
    for record in self.__dnsRecords.getRecords():
      if filter( record ):
        ret.append( record )
    return ret

  def getNetworks(self, filter = lambda rec: 1):
    ''' return a list of networks it has records on'''
    ret = []
    for record in self.__dnsRecords.getRecords():
      if filter(record) and record.recordNet not in ret:
        ret.append( record.recordNet )
    ret.sort()
    return ret

  def host2Str(self, prefix=""):
    ret = []
    ret.append(prefix + "Host(Domain): " + self.shortname + "(" + self.domainname + ")")
    for record in self.__otherRecords.getRecords():
      ret.append(prefix + record.recordType + ": " + record.recordData)
    if len(self.__dnsRecords.getRecords()) > 0:
      ret.append(prefix + "--DNS Entries--")
      for record in self.__dnsRecords.getRecords():
        ret.append(prefix + "%s" % record)
    return "\n".join(ret)

  def __str__(self):
    return self.host2Str("")

  def printHost(self, prefix=""):
    """ printHost(XMLHost) - prints a human readable output of an XMLHost object 

    """
    print self.host2Str(prefix)
    print prefix + "--------------------------------------------------------------------------------"

  # returns an xml (string) representation of the host object
  def dumpXML(self):
    ret = ""
    ret += "  <host>\n"
    ret += "    <hostname>" + self.shortname + "." + self.domainname + "</hostname>\n"
    ret += "    <shortname>" + self.shortname + "</shortname>\n"
    ret += "    <domainname>" + self.domainname + "</domainname>\n"
    for record in self.__otherRecords.getRecords():
      ret += "    <" + record.recordType + '>' + record.recordData + '</' + record.recordType + '>' + "\n"
    for record in self.__dnsRecords.getRecords():
      ttl=''
      if record.recordTTL:
        ttl=' ttl="' + record.recordTTL + '"'
      ret += "    <" + record.recordType + ' net="' + record.recordNet + '"' + ttl + '>' + record.recordData + '</' + record.recordType + '>' + "\n"
    ret += "  </host>\n" 
    return ret

  def expandMac(self, macAddress):
    '''turn 0:1:2:3:4:5 into 00:01:02:03:04:05 for ease of comparison'''
    def twolong(a):
      if len(a) < 2:
        return "0" + a
      return a

    pieces = map(twolong, macAddress.split(":"))
    return ":".join(pieces).lower()

  def hasMac(self, macAddress):
    '''hasMac(self, macAddress) -> 0/1 (false/true)

    determines if macAddress is contained in this entry
    '''
    macAddress = self.expandMac( macAddress )
    for record in self.__otherRecords.getRecords():
      if record.recordType == 'macAddress':
        if self.expandMac(record.recordData) == macAddress:
          return 1
    return 0

  def hasNetwork(self, netName):
    '''hasNetwork(self, netName) -> 0/1 (false/true)

    determines if any DNS record is labeled for the network netName
    NB: a record can appear on a network from an implicit name since each net can inherit
        records from another network
    '''
    for record in self.__dnsRecords.getRecords():
      if record.recordNet == netName:
        return 1
    return 0

  def hasIP(self, netIP):
    '''hasIP(self, netIP) -> 0/1 (false/true)

    determines if any DNS record is the desired IP
    TODO: simplify IPv6 records to a single possible instance across the board.
          this means dealing with cases like 2607:f088:0:5::1 ... we should research
          a little to find a pre-build module to do this for us.
    '''
    for record in self.__dnsRecords.getRecords():
      if record.recordData == netIP:
        return 1
    return 0

  def containsRecordType(self, recordType):
    '''containsRecordType(self, recordType) -> 0/1 (false/true)

    determines if any record (DNS or otherwise) is stored in this host entry
    '''
    for record in self.__dnsRecords.getRecords():
      if record.recordType == recordType:
        return 1
    for record in self.__otherRecords.getRecords():
      if record.recordType == recordType:
        return 1
    return 0

class RecordList:
  """Maintains a list of Record instances
  """

  def __init__(self):
    self.__records = []

  def add(self, recordType, recordData):
    self.__records.append( Record(recordType, recordData) )

  def remove(self, recordType, recordData):
    targetRecord = Record( recordType, recordData )
    if targetRecord in self.__records:
      return self.__records.remove( targetRecord )
    return None

  def getRecords(self):
    self.__records.sort()
    return self.__records

class DNSRecordList(RecordList):
  """Maintains a list of DNSRecord instances

  """

  def __init__(self):
    # Call super-class init and create dnsRecords list
    RecordList.__init__(self)
    self.__dnsRecords = []

  # adds a DNS record to the list
  def add(self, recordType, recordData, recordNet, recordTTL):
    self.__dnsRecords.append( DNSRecord(recordType, recordData, recordNet, recordTTL) )

  def remove(self, recordType, recordData, recordNet):
    targetRecord = DNSRecord( recordType, recordData, recordNet )
    if targetRecord in self.__dnsRecords:
      return self.__dnsRecords.remove( targetRecord )
    return None

  # returns list of dnsRecord objects
  def getRecords(self):
    self.__dnsRecords.sort()
    return self.__dnsRecords

class Record:
  """Contains data for a single (non-DNS) record:

  recordType - a/aaaa/loc/...
  recordData - 192.168.1.1/2607:f088::1/... 
  """

  def __init__(self, recordType, recordData):
    self.recordType = recordType
    self.recordData = recordData

  def __str__(self):
    return "%5s: %s" % ( self.recordType, self.recordData )

  # Rich comparison for records
  def __cmp__(self, other):
    # Sort by data type first
    res = cmp( self.recordType, other.recordType )
    if res != 0:
      return res
    # Then sort by data
    return cmp( self.recordData, other.recordData )

  def __eq__(self, other):
    return self.recordType == other.recordType and \
      self.recordData == other.recordData

  def __ne__(self, other):
    return self.recordType != other.recordType or \
      self.recordData != other.recordData

class DNSRecord(Record):
  """Contains data for a single DNS record:

  recordType - a/aaaa/loc/...
  recordData - 192.168.1.1/2607:f088::1/... 
  recordNet - building1 net
  """

  def __init__(self, recordType, recordData, recordNet, recordTTL=None):
    self.recordType = recordType
    self.recordData = recordData
    self.recordNet  = recordNet
    self.recordTTL  = recordTTL

  def __str__(self):
    if self.recordTTL:
    	return "%5s [%s]: %s (ttl=%s)" % ( self.recordType, self.recordNet, self.recordData, self.recordTTL )
    return "%5s [%s]: %s" % ( self.recordType, self.recordNet, self.recordData )

  # Rich comparison for records
  def __cmp__(self, other):
    # Sort by data type first
    res = cmp( self.recordType, other.recordType )
    if res != 0:
      return res
    # Then sort by network
    res = cmp( self.recordNet, other.recordNet )
    if res != 0:
      return res
    # Then sort by data
    return cmp( self.recordData, other.recordData )

  def __eq__(self, other):
    return self.recordType == other.recordType and \
      self.recordNet == other.recordNet and \
      self.recordData == other.recordData

  def __ne__(self, other):
    return self.recordType != other.recordType or \
      self.recordNet != other.recordNet or \
      self.recordData != other.recordData

# Some commands that should be cleaned up/moved into a class at some point
# The structure of these is pretty ugly but they get the job done (for now)

class ListFactory:
  """produces various lists generally from XML files"""

  def __init__(self, doc_base):
    """doc_base should be the directory that contains host_list.xml and others"""
    self.__doc_base = doc_base

  def getXMLDomainList(self):
    """Generate an XML object with domains from an XML document (just provide a document base directory)"""
    # doc = xml.dom.minidom.parse(host_list_doc_base + "host_list_new.xml");
    # print "Reading host list..."
    try:
      fhandle = open(self.__doc_base + "domain_list.xml", "r")
    except IOError:
      print "File does not exist!"
      system.exit(-1)
    nws = re.compile('>\s+<')
    nlws = re.compile('>\s+')
    ntws = re.compile('\s+<')
    # TODO: make this a little more efficient...
    # Get contents of file without the killer whitespace
    # split the file on the "nws" pattern
    # join the contents of the file with ><
    contents = "><".join(nws.split(fhandle.read()))
    # same, get rid of leading whitespace
    contents = ">".join(nlws.split(contents))
    # same, get rid of trailing whitespace
    contents = "<".join(ntws.split(contents))
    fhandle.close()
    # Make a DOM object out of this stripped down xml
    doc = xml.dom.minidom.parseString(contents)
    return doc

  def getXMLNetworkList(self):
    """Generate an XML object with networks from an XML document (just provide a document base directory)"""
    try:
      fhandle = open(self.__doc_base + "net_list.xml", "r")
    except IOError:
      print "File does not exist!"
      system.exit(-1)
    nws = re.compile('>\s+<')
    nlws = re.compile('>\s+')
    ntws = re.compile('\s+<')
    # TODO: make this a little more efficient...
    # Get contents of file without the killer whitespace
    # split the file on the "nws" pattern
    # join the contents of the file with ><
    contents = "><".join(nws.split(fhandle.read()))
    # same, get rid of leading whitespace
    contents = ">".join(nlws.split(contents))
    # same, get rid of trailing whitespace
    contents = "<".join(ntws.split(contents))
    fhandle.close()
    # Make a DOM object out of this stripped down xml
    doc = xml.dom.minidom.parseString(contents)
    return doc

  def getXMLHostList(self):
    """Generate an XML object with hosts from an XML document (just provide a document base directory)"""
    # doc = xml.dom.minidom.parse(host_list_doc_base + "host_list_new.xml");
    # print "Reading host list..."
    try:
      fhandle = open(self.__doc_base + "host_list.xml", "r")
    except IOError:
      print "File does not exist!"
      system.exit(255)
    nws = re.compile('>\s+<')
    nlws = re.compile('>\s+')
    ntws = re.compile('\s+<')
    # TODO: make this a little more efficient...
    # Get contents of file without the killer whitespace
    # split the file on the "nws" pattern
    # join the contents of the file with ><
    contents = "><".join(nws.split(fhandle.read()))
    # same, get rid of leading whitespace
    contents = ">".join(nlws.split(contents))
    # same, get rid of trailing whitespace
    contents = "<".join(ntws.split(contents))
    fhandle.close()
    # Make a DOM object out of this stripped down xml
    doc = xml.dom.minidom.parseString(contents)
    return doc

  ## Write the host list to nv storage
  def writeXMLHostList(self, state):
    """Given a ProgState with an XMLHostList, writes an xml representation back to nv storage

    """
    try:
      fhandle = open(self.__doc_base + "host_list.xml", "w")
    except IOError:
      print "File does not exist!"
      return -1
    print "Generate XML output..."
    xml = state.getHostList().dumpXML()
    print "Save output..."
    fhandle.write(xml)
    # fhandle.write(hostList.dumpXML())
    fhandle.close()
    return 0

  ## From an XML object with hosts, generate an XMLHostList object
  def getDomainListFromXML(self, xmlDomainList):
    """Given an xmlNode version of a domain list, returns an XMLDomainList instance"""
    domainList = XMLDomainList()
    domainList.seedDomainsFromXML(xmlDomainList)
    return domainList

  ## From an XML object with hosts, generate an XMLHostList object
  def getNetworkListFromXML(self, xmlNetworkList):
    """Given an xmlNode version of a network list, returns an XMLNetworkList instance"""
    networkList = XMLNetworkList()
    networkList.seedNetworksFromXML(xmlNetworkList)
    return networkList

  ## From an XML object with hosts, generate an XMLHostList object
  def getHostListFromXML(self, xmlHostList):
    """Given an xmlNode version of a host list, returns an XMLHostList instance"""
    hostList = XMLHostList()
    hostList.seedHostsFromXML(xmlHostList)
    return hostList


################################################################################
# State related classes ########################################################
################################################################################

class ProgState:

  def __init__(self, hostList, networkList = None, domainList = None):
    self.__hostList = hostList
    self.__networkList = networkList
    self.__domainList = domainList

    self.__currentHost = None
    self.__log = []

  def getHostList(self):
    ''' Returns the current XMLHostList object '''
    return self.__hostList

  def getDomainList(self):
    ''' Returns the current XMLDomainList object '''
    return self.__domainList

  def getNetworkList(self):
    ''' Returns the current XMLNetworkList object '''
    return self.__networkList

  def getListFactory(self):
    ''' Returns the ListFactory object '''
    return self.__listFactory

  def setListFactory(self, listFactory = None):
    ''' Sets and returns the ListFactory object '''
    self.__listFactory = listFactory
    return self.__listFactory

  def getCurrentHost(self):
    ''' Returns the current/selected XMLHost object '''
    return self.__currentHost

  def setCurrentHost(self, currentHost = None):
    ''' Sets and returns the current/selected XMLHost object '''
    self.__currentHost = currentHost
    return self.__currentHost

  def appendLog(self, entry):
    ''' append information to the running log '''
    if not(self.__currentHost):
      return self.appendLogLiteral(entry)

    logEntry = "%s.%s: %s" % (self.__currentHost.shortname, self.__currentHost.domainname, entry)
    return self.__log.append( logEntry ) or 1

  def appendLogLiteral(self, entry):
    ''' Don't pre-pend any information about host context '''
    return self.__log.append( entry ) or 1

  def getLog(self):
    return "\n".join(self.__log)

