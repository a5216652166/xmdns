#!/usr/bin/env python

import xmldns
import xmldns.validator
import sys
import os
import re

# Really, this should have been a class with the state available as instance
# variables but I guess I am still thinking like a c programmer
def stateInit():
  ''' Initializes/returns the state object '''
  # doc_base = "../../res/db/"
  doc_base = "res/db/"
  listFactory = xmldns.ListFactory(doc_base)
  print "Initializing host list from xml..."
  xmlHostList = listFactory.getXMLHostList()
  hostList    = listFactory.getHostListFromXML(xmlHostList)
  print "Initializing network list from xml..."
  xmlNetworkList = listFactory.getXMLNetworkList()
  networkList    = listFactory.getNetworkListFromXML(xmlNetworkList)
  print "Initializing domain list from xml..."
  xmlDomainList = listFactory.getXMLDomainList()
  domainList    = listFactory.getDomainListFromXML(xmlDomainList)
  state       = xmldns.ProgState(hostList, networkList, domainList)
  state.setListFactory( listFactory )
  return state

################################################################################
# Generic functions to make life easier ########################################
################################################################################

def getMenuOption( state, menuName, optionDict, optionSelector, optionImplementor, finalOptionSelector, statusInjector = None ):
  '''getMenuOption( state, menuName, optionDict, optionSelector, optionImplementor, finalOptionSelector )

  A generic handler for a menu implemented as a generator.
  state: ProgState Instance
  menuName: String (or printable) object describing the menu
  optionDict: A dictionary of options: 'a':'text describing option'
  optionSelector: a lambda/function that provides the order (and existance) of the menu options
  optionImplementor: a lambda/function that gets called (option, state) with valid options
  finalOptionSelector: a lambda/function that decides the finishing option (exit/quit/...)
  statusInjector: an instance of StatusInjector (optional) to display output before the menu is printed
  '''
  log = 'static log'
  optionLen = 1
  for options in optionDict.keys():
    if optionLen < len(options):
      optionLen = len(options)
  formatHeaderString	= '%%%ds:' % (optionLen + 2)
  formatString		= '%%%ds) %%s' % (optionLen + 2)
  while 1:
    os.system('clear')
    sys.stdout.write("== " + menuName + " ==\n\n")

    # Show the host we are currently editing
    if state.getCurrentHost():
      state.getCurrentHost().printHost("| ")
    else:
      print "| No host currently selected"
    print

    if statusInjector != None:
      print statusInjector.getStatus()
      print

    # print menu
    print formatHeaderString % ( 'Menu Options' )
    for option in optionSelector():
      print formatString % ( option,  optionDict[option] )

    # get selection
    sys.stdout.write("\n  Selection: ")
    option = sys.stdin.readline().rstrip()
    if not( option in optionSelector() ):
      print "Invalid selection!"
      print "'" + option + "'"
      sys.stdout.write("Press Enter to continue...")
      sys.stdin.readline()
    else:
      if not( finalOptionSelector(option)):
        optionImplementor( option, state )
      yield (option, log)

def getInput(inputPrompt):
  '''Asks user for input'''
  sys.stdout.write("  " + inputPrompt + ": ")
  return sys.stdin.readline().rstrip()

class StatusInjector:
  """ used to "inject" status into a menu generator """
  def __init__(self):
    self._status = ""
  def setStatus(self, status):
    self.__status = status
  def getStatus(self):
    return self.__status

def chooseNetwork( state, prevMenuName = "" ):
  """ Ask the user to choose from a list of available networks """
  menuName = prevMenuName + " > Choose Network "
  networkList = state.getNetworkList().getList()
  optionDict = {}
  for network in networkList:
    description = []
    prefixList = network.getRecordsOfType('prefix')
    for prefix in prefixList:
      description.append(prefix.recordData)
    optionDict[network.name] = "\t- ".join(description)
  options = optionDict.keys()
  options.sort()
  optionSelector = lambda: options
  finalOptionSelector = lambda option: 1
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, None, finalOptionSelector )
  (network, log) = menuGen.next()
  return network

def chooseDomain( state, prevMenuName = "" ):
  """ Ask the user to choose from a list of available domains """
  # Generate a menu to select a domain
  menuName = prevMenuName + " > Choose Domain"
  optionDict = {}
  for domains in state.getDomainList().getList():
    records = domains.getRecordsOfType('description')
    description = ""
    if len(records) > 0:
      description = records[0].recordData
    optionDict[ domains.name ] = description
  optionSelector = lambda: optionDict.keys()
  # implement options by ourself
  optionImplementor = lambda option, state: option == option
  finalOptionSelector = lambda option: 1
  statusInjector = StatusInjector()
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, optionImplementor, finalOptionSelector, statusInjector )
  statusInjector.setStatus("")
  (domain, log) = menuGen.next()
  return domain

################################################################################
# Functions related to filtering hosts #########################################
################################################################################

def filterMenuOptionSelector(state):
  ''' Always returns all options (for now) '''
  return ['h','d','i','n','l','q']

# Generates smaller and smaller lists until there is one or less host
def lookupHostGen(state):
  # Initial filter is blank
  humanFilter = ""
  # Generate options from stdin :)
  # menuGen = getLookupHostMenuGenerator()
  # key: (humanreadable filter, hostList filter)
  actions = {
    'h':(lambda word: "(hostname=" + word + ")", lambda host, hostname: host.shortname == hostname),
    'd':(lambda word: "(domain=" + word + ")",   lambda host, domain: host.domainname == domain),
    'n':(lambda word: "(network=" + word + ")",  lambda host, network: host.hasNetwork(network)),
    'i':(lambda word: "(ip=" + word + ")",       lambda host, ip: host.hasIP(ip)),
    'l':(lambda word: "",                        lambda host, ip: host.printHost() or 1),
    'q':(lambda word: "",                        lambda host, ip: 0),
    }

  # How to prompt for input given a specific query
  prompts = {
    'h':(lambda: getInput("hostname")),
    'd':(lambda: chooseDomain(state,  "XML Host Editor > Lookup Host - Filter")),
    'n':(lambda: chooseNetwork(state, "XML Host Editor > Lookup Host - Filter")),
    'i':(lambda: getInput("ip")),
    'l':(lambda: ""),
    'q':(lambda: "")
    }

  # Generate a menu
  menuName = "XML Host Editor > Lookup Host - Filter"
  optionDict = {
    'h':('hostname'),
    'd':('domain'),
    'i':('ip address'),
    'n':('network'),
    'l':('list hosts'),
    'q':('quit/leave filter')
  }
  optionSelector = lambda: filterMenuOptionSelector(state)
  # implement options by ourself
  optionImplementor = lambda option, state: option == option
  finalOptionSelector = lambda option: option == 'q'
  statusInjector = StatusInjector()
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, optionImplementor, finalOptionSelector, statusInjector )

  # Start with full host list
  hostList = state.getHostList()

  # until we are down to a single host or less, keep asking for more filter options
  while len(hostList.getList()) > 1:
    # Some status output
    # print len(hostList.getList()), "hosts with current filter: " + humanFilter
    statusInjector.setStatus( "%(numHosts)d hosts with current filter: %(humanFilter)s" % {
      'numHosts': len(hostList.getList()),
      'humanFilter': humanFilter
      } )

    # yield before we filter down
    yield (hostList, humanFilter)

    # Get option from user
    (opt, log) = menuGen.next()
    # Figure out how to filter using this option
    (qs, filter) = actions[opt];
    # Get input about option (unless we are just listing hosts)
    # and append filter description
    if not( opt in ['l','q'] ):
      inputPrompt = prompts[opt]
      input = inputPrompt()
      humanFilter += qs(input)
    else:
      input = ''
    # filter down hosts
    hostList = hostList.filteredList(filter,input)
    # When we lists hosts, don't clear the screen immediately
    if opt == 'l':
      sys.stdout.write("Press Enter to continue...")
      sys.stdin.readline()
  # once done, yeild result
  yield (hostList, humanFilter)

def lookupHost(state):
  '''Interactively lookup a host'''

  # Don't display a current host when looking for (another) host
  state.setCurrentHost(None)

  # use a generator to whittle the list down to a single host
  getHost = lookupHostGen(state)
  notDone = 1
  while notDone:
    (filteredList, humanFilter) = getHost.next()
    if len( filteredList.getList() ) < 2:
      notDone = 0

  ## If we found our host, set it up... otherwise we have over-filtered (oh well)
  if len( filteredList.getList() ) == 1:
    state.setCurrentHost(filteredList.getList()[0])
  else:
    print "No hosts match this filter: " + humanFilter
    print "Press ENTER to continue..."
    sys.stdin.readline()
    state.setCurrentHost(None)

################################################################################
# Adding a host is simple ######################################################
################################################################################

def addHost(state):
  '''Add a new host'''

  # Hack to give a little space between previous prompt and new prompt
  print

  # Get the most basic paramters for the host
  domain = chooseDomain(state, "XML Host Editor > Add Host")
  hostname = getInput("hostname")

  # Look for other instances of the same host/domain pair
  newHost = xmldns.XMLHost(domain, hostname)
  filter = lambda host, input: host.shortname == hostname and host.domainname == input
  searchedHostList = state.getHostList().filteredList(filter,domain)
  # Warn user about duplicate hosts and verify that this is actually wanted
  if len( searchedHostList.getList() ) > 0:
    print "Warning: there is already another entry with the same name!"
    searchedHostList.filteredList( lambda host, input: host.printHost() or input, 1 )
    sys.stdout.write("Continue adding host? (Y/n): ")
    yn = sys.stdin.readline()[0].rstrip().lower()
    if yn == '':
      yn = 'y'
    if yn != 'y':
      print "Skipping host."
      return None
    else:
      newHost.addRecord('known-duplicate', 'hostname+domain duplicated')

  # Actually add host...
  state.getHostList().addHost(newHost)
  state.setCurrentHost(newHost)
  state.appendLog("Added host")
  return newHost

################################################################################
# Routines to modify a host ####################################################
################################################################################
def doAddRecordMenuAction( option, state ):
  option_actions = {
    'a':		(''),
    'aaaa':		(''),
    'cname':		(''),
    'loc':		(''),
    'mx':		(''),
    'ns':		(''),
    'ptr':		(''),
    'rp':		(''),
    'srv':		(''),
    'txt':		(''),
    'action':		(''),
    'description':	(''),
    'known-duplicate':	(''),
    'macAddress':	(''),
    'manager':		(''),
    'notes':		(''),
    }

  ## We need to know when to ask for a network...
  dnsRecords = [ 'a', 'aaaa', 'cname', 'loc', 'mx', 'ns', 'ptr', 'rp', 'srv', 'txt' ]
  networkName = None
  if option in dnsRecords:
    networkName = chooseNetwork( state, "XML Host Editor > Modify Host > Add Record (" + option + ")" )
  # Find the next IPv4 address and report it
  if option == 'a':
    filter = lambda rec: rec.recordType == 'a' and rec.recordNet == networkName
    netRecords = state.getHostList().getDNSRecords( filter )
    network = state.getNetworkList().getNetwork( networkName )
    prefices = network.getRecordsOfType( 'prefix' )
    ## Really Ugly... oh well
    for prefix in prefices:
      if re.match("^\d+\.\d+\.\d+\.\d+/24$", prefix.recordData):
        print "  Free IPv4 records in " + prefix.recordData
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
          if not(found) and foundCount < 5:
            foundCount = foundCount + 1
            print "    " + freeIP
  validator = xmldns.validator.RecordValidator( state )
  recordData = None
  while not( recordData ):
    recordData = getInput(option + " record data")
    recordData = validator.validRecord( option, recordData )
  currentHost = state.getCurrentHost()
  # Add record appropriately
  if option in dnsRecords:
    state.appendLog("Added: %s [%s]: %s" % (option, networkName, recordData))
    return currentHost.addDNSRecord( option, recordData, networkName )
  state.appendLog("Added: %s: %s" % (option, recordData))
  return currentHost.addRecord( option, recordData )

def addRecordOptionSelector(state):
  currentHost = state.getCurrentHost()
  if currentHost == None:
    return ['e']
  shortname = currentHost.shortname
  options = []
  if not( "_" in shortname ):
    options.append( 'a' )
    options.append( 'aaaa' )
    options.append( 'cname' )
    options.append( 'mx' )
    options.append( 'ns' )
    options.append( 'ptr' )
  options.append( 'rp' )
  options.append( 'srv' )
  options.append( 'txt' )
  options.append( 'action' )
  options.append( 'description' )
  options.append( 'macAddress' )
  options.append( 'notes' )
  options.append( 'e' )
  if not( currentHost.containsRecordType('known-duplicate') ):
    options.insert(12, 'known-duplicate')
  if not( currentHost.containsRecordType('manager') ):
    options.insert(14, 'manager')
  return options

def addRecord(state):
  '''addRecord(state)

  adds records to the current host
  '''

  # Generate a menu
  menuName = "XML Host Editor > Modify Host > Add Record"
  optionDict = {
    'a':('A - IPv4 Address'),
    'aaaa':('AAAA - IPv6 Address'),
    'cname':('CNAME'),
    'loc':('Location'),
    'mx':('Mail Exchange'),
    'ns':('Name Server'),
    'ptr':('Pointer'),
    'rp':('Responsible Person'),
    'srv':('Server'),
    'txt':('Text'),
    'action':('Action'),
    'description':('Description'),
    'known-duplicate':('Known Duplicate'),
    'macAddress':('MAC Address'),
    'manager':('Manager'),
    'notes':('Notes'),
    'e':('exit/stop adding records'),
    }
  optionSelector = lambda: addRecordOptionSelector(state)
  finalOptionSelector = lambda option: option == 'e'
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, doAddRecordMenuAction, finalOptionSelector )

  addRecordMenuNotDone = 1
  while addRecordMenuNotDone:
    (opt, log) = menuGen.next()
    if opt == 'e':
      addRecordMenuNotDone = 0
      continue

def deleteRecordHelper( state ):
  ''' Keep consistant state between menu generator and implementor '''
  (dnsRecords, otherRecords) = state.getCurrentHost().getRecords()
  optionDict = {
    'e':('exit/stop removing records'),
    }
  i = 0
  recordPos = []
  for record in dnsRecords:
    key = "%.2d" % i
    optionDict[ key ] = record
    recordPos.append( record )
    i += 1
  # remember where dns ends and non-dns begins
  dnsEnd = i
  for record in otherRecords:
    optionDict[ "%.2d" % i ] = record
    recordPos.append( record )
    i += 1
  return (optionDict, recordPos, dnsEnd)

def doDeleteRecordMenuAction( option, state ):
  (optionDict, recordPos, dnsEnd) = deleteRecordHelper(state)
  if not( option.isdigit() ):
    return None
  option = int(option)
  targetRec = recordPos[ option ]
  state.appendLog("Removed: %s" % targetRec)
  if option >= dnsEnd:
    return state.getCurrentHost().removeRecord( targetRec.recordType, targetRec.recordData )
  print "Remove DNS record since %d > %d" % (option, dnsEnd)
  return state.getCurrentHost().removeDNSRecord( targetRec.recordType, targetRec.recordData, targetRec.recordNet )

def deleteRecordOptionSelector(state, options):
  options.sort()
  return options

def deleteRecord(state):
  '''deleteRecord(state)

  deletes records from the current host
  '''

  # Generate a menu
  option = None
  while option != 'e':
    menuName = "XML Host Editor > Modify Host > Remove Record"
    (optionDict, recordPos, dnsEnd) = deleteRecordHelper(state)
    optionSelector = lambda: deleteRecordOptionSelector(state, optionDict.keys())
    finalOptionSelector = lambda option: option == 'e'
    menuGen = getMenuOption( state, menuName, optionDict, optionSelector, doDeleteRecordMenuAction, finalOptionSelector )
    (option, log) = menuGen.next()

def doModifyMenuAction( option, state ):
  option_actions = {
    'a':(lambda s: addRecord(s)        ),
    'd':(lambda s: deleteRecord(s)     ),
    }
  lam = option_actions[option]
  return lam(state)

def modifyHostOptionSelector(state):
  if state.getCurrentHost() != None:
    return ['a','d','e']
  return ['e']

def modifyHost(state):
  '''Modify a host entry'''

  # Generate a menu
  menuName = "XML Host Editor > Modify Host"
  optionDict = {
    'a':('add record'               ),
    'd':('delete record'            ),
    'e':('exit/finish modifications')
  }
  optionSelector = lambda: modifyHostOptionSelector(state)
  finalOptionSelector = lambda option: option == 'e'
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, doModifyMenuAction, finalOptionSelector )

  modifyMenuDone = 0
  while not modifyMenuDone:
    (opt, log) = menuGen.next()
    if opt == 'e':
      modifyMenuDone = 1

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

def doMainMenuAction( option, state ):
  option_actions = {
    # 'q':(lambda s: s.printLog() ),
    'a':(lambda s: addHost(s)        ),
    'l':(lambda s: lookupHost(s)     ),
    's':(lambda s: saveChanges(s)),
    'm':(lambda s: modifyHost(s)     ),
    'd':(lambda s: s.appendLog("Removed entry") and s.setCurrentHost(s.getHostList().removeHost(s.getCurrentHost())) )
    }
  lam = option_actions[option]
  return lam(state)

def mainMenuOptionSelector(state):
  if state.getCurrentHost():
    return ['a','d','m','l','s','q']
  return ['a','l','s','q']

## What to do if we are called directly as an editor
if __name__ == "__main__":
  mainMenuDone = 0
  state = stateInit()
  # menuGen = getMainMenuOption(state)

  # Generate a menu
  menuName = "XML Host Editor"
  optionDict = {
    'a':('add new host'       ),
    'd':('delete current host'),
    'm':('modify current host'),
    'l':('lookup/select host' ),
    's':('save changes'       ),
    'q':('quit'               )
  }
  optionSelector = lambda: mainMenuOptionSelector(state)
  finalOptionSelector = lambda option: option == 'q'
  menuGen = getMenuOption( state, menuName, optionDict, optionSelector, doMainMenuAction, finalOptionSelector )
  # menuGen = getMainMenuOption(state)
  # HERE
  while not mainMenuDone:
    (opt, log) = menuGen.next()
    if opt == 'q':
      mainMenuDone = 1
  print "Session Log:"
  print state.getLog()
  print "--------------------------------------------------------------------------------"

