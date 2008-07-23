#!/usr/bin/env python

import re

class RecordValidator:

  def __init__( self, state ):
    self.__state = state

  def validRecord( self, recordType, recordData, networkName = None ):
    '''validRecord( self, recordType, recordData, networkName = None ) -> None/Minimized record (false/true)

    Validates an arbitrary record, optionally against a particular network'''
    validator = self.getValidator( recordType )
    return validator.validRecord( recordType, recordData, networkName )

  def getValidator( self, recordType ):
    ''' __getValidator( self, recordType ) -> instance of RecordValidator class (subclass)

    For a given recordType, return a validator '''
    validators = {
      'a':(AValidator),
      'aaaa':(AAAAValidator),
      'cname':(FQDNValidator),
      'mx':(MXValidator),
      'ns':(FQDNValidator),
      'srv':(SRVValidator),

      'fqdn':(FQDNValidator),
      }
    if not (recordType in validators.keys()):
      return DefaultValidator( self.__state )
    return validators[ recordType ]( self.__state )

# For unknown records, just assume they are good if they are one line and move on
class DefaultValidator(RecordValidator):
  ''' Return true for all records '''
  def __init__( self, state ):
    self.__state = state
  def validRecord( self, recordType, recordData, networkName = None ):
    if "\n" in recordData:
      return None
    return recordData

class AddressValidator(RecordValidator):
  ''' Validate an Address (IPv4/IPv6):

  checks for valid syntax:
    ip is within dedicated network prefix
    IPv4
      each byte fits in a byte (0-255)
      matches ^\d+.\d+.\d+.\d+$
    IPv6
      each segment is between 0-ffff
      each segment is a pure hex entity
      only one :: found in ip
      at least one :: found if a segment == 0
        + :: is in the place of the longest sequential set of 0's
      ::ffff:aabb:ccdd is an IPv4 address
      ::ffff:AAA.BBB.CCC.DDD is an IPv4 address
        - should this be a warning or a feature? 
        - should detected IPv4 address be converted/added?
  '''

  def __init__( self, state ):
    self.__state = state

  def setIP(self, ip):
    ''' setAddress(self, ip)

    ip can be an IPv4/IPv6 address
    '''
    self.__ip = ip
    if self.isIPv4() or self.isIPv6():
      return self.__ip

    # Be nice and try to parse IPv4 mapped/compatible addresses
    if self.isIPv4InIPv6():
      self.__ip = re.sub(".*:", '', ip)
    else:
      self.__ip = None
    return self.__ip

  def getIP(self):
    ''' setAddress(self, ip)
    '''
    return self.__ip

  def setPrefix(self, prefix):
    ''' setPrefix(self, prefix)

    ip can be an IPv4/IPv6 address range in CIDR notation:
    AAA.BBB.CCC.DDD/EE
    aaaa:bbbb:cccc::/dd
    '''
    self.__prefix = prefix
    return self.__prefix

  def getPrefix(self):
    ''' getPrefix(self)
    '''
    return self.__prefix

  def setPrefixFromNetworkName(self, networkName):
    '''TODO: get network prefix list from network name'''
    self.setPrefix(None)

  def validRecord( self, recordType, recordData, networkName = None ):
    '''validRecord( self, recordType, recordData, networkName = None ) -> 0/1 (false/true)
    '''
    self.setIP( recordData )
    self.setPrefixFromNetworkName( networkName )
    return None

  ## Internal Validator/Helper functions
  def isIPv4(self):
    if not( self.getIP()) or not( re.match('^\d+\.\d+\.\d+\.\d+$', self.getIP()) ):
      return None
    pieces = self.getIP().split('.')
    if len( pieces ) != 4:
      return None
    for p in pieces:
      if int( p ) > 255 or int( p ) < 0:
        return None
    return 1

  def isIPv6(self):
    if not( self.getIP() ) or not( re.search(":", self.getIP()) ):
      return None
    pieces = self.getIP().split(':')
    if len( pieces ) > 8:
      return false
    for p in pieces:
      if not( re.match('^[a-fA-F0-9]*$', p) ):
        return None
    return self.getIP()

  def isIPv4InIPv6(self):
    ''' returns true for addresses like: ::ffff:128.196.0.0 (and even ::ffff:80c4:0 ?) '''
    if not( self.getIP() ):
      return None
    return re.search(r":ffff:\d+\.\d+\.\d+\.\d+$", self.getIP()) or \
	   re.search(r"^::\d+\.\d+\.\d+\.\d+$", self.getIP())

  def __isParsable(self):
    pass

class AValidator(AddressValidator):

  def validRecord( self, recordType, recordData, networkName = None ):
    '''validRecord( self, recordType, recordData, networkName = None ) -> None/Address (false/true)
    '''
    self.setIP( recordData )
    if not( self.isIPv4() ):
      return self.setIP( None )
    self.setPrefixFromNetworkName( networkName )
    return self.minimizeAddress()

  def minimizeAddress( self ):
    if not( self.getIP() ):
      return None
    quad = self.getIP().split('.')
    numQuad = []
    for num in quad:
      numQuad.append( "%d" % int(num) )
    minimalIP = ".".join(numQuad)
    return minimalIP

class AAAAValidator(AddressValidator):

  def validRecord( self, recordType, recordData, networkName = None ):
    '''validRecord( self, recordType, recordData, networkName = None ) -> None/Address (false/true)
    '''
    self.setIP( recordData )
    if not( self.isIPv6() ):
      return self.setIP( None )
    self.setPrefixFromNetworkName( networkName )
    return self.minimizeAddress()

  # Kinda inefficient ... but works
  def fillAddress( self ):
    if not( self.getIP() ):
      return None
    # split the current IP on : and count up the specified words
    pieces = self.getIP().split(":")
    total = len( pieces ) - 1
    # Take care of end (edge) cases
    if pieces[0] == '':
      pieces[0] = '0'
    if pieces[total] == '':
      pieces[total] = '0'
    # Create appropriate filler for middle of address
    center = ":".join( map( lambda word: '0', range(8-total) ) )
    # Not efficient but place filler in the right place(s) and put the address back together
    fullPieces = map( lambda word: word != '' and word or center, pieces )
    filledIP = ":".join(fullPieces)
    # if re.match("^([a-fA-F0-9]+:){7,7}\[a-fA-F0-9]+$", filledIP):
    if re.match("^([a-fA-F0-9]+:){7,7}[a-fA-F0-9]+$", filledIP):
      return filledIP
    return None

  # Grossly inefficient ... but works
  def minimizeAddress( self ):
    fullIP = self.fillAddress()
    if not( fullIP ):
      return None
    compressed = ":".join( \
                          map( lambda word: "%x" % int( word, 16 ), \
                               fullIP.split(":")
                             ) \
                         )
    compressed = compressed.replace(":0", ":")
    compressed = re.sub("^0:", ":", compressed)

    # ::::::: - 7
    # TOKEN -> ::
    # a:::::::b - 7
    # aTOKENb -> a::b
    # a::::b:::c - 4
    # aTOKENb:::c -> aTOKENb:0:0:c -> a::b:0:0:c

    for maxLen in [7,6,5,4,3,2]:
      matchString = ":{%d,%d}" % ( maxLen, maxLen )
      if re.search( matchString, compressed ):
        target = "".join(map( lambda word: ':', range( maxLen ) ))
        replacement = "TOKEN"
        stage = re.sub(target, replacement, compressed, 1)
        stage = re.sub(":$", ":0", stage)
        # Ugh, it would be nice to be able to just replace :: with :0: but ::: becomes :0::
        # So we have to do this multiple times :(
        stage = stage.replace("::", ":0:")
        stage = stage.replace("::", ":0:")
        stage = stage.replace("::", ":0:")
        stage = stage.replace(replacement, "::")
        return stage
    # PUNT!
    return fullIP

# For records that should be a hostname, this validates hostnames
# (and removes trailing .)
class FQDNValidator(RecordValidator):
  ''' Return true for all records '''
  def __init__( self, state ):
    self.__state = state
  def validRecord( self, recordType, recordData, networkName = None ):
    # Eliminate trailing .
    recordData = re.sub("\.$", "", recordData)
    pieces = recordData.split('.')
    for p in pieces:
      # Each piece can only be 53 characters long,
      # can not be a pure number
      # can not begin with -
      # can not end with -
      tests = {}
      tests['length']		= (lambda p: len(p) > 53)
      tests['alphanumeric']	= (lambda p: not( re.search('^[a-zA-Z0-9\-]+$', p) ))
      tests['pure number']	= (lambda p: re.search('^[0-9]$', p))
      tests['begins with -']	= (lambda p: re.search('^-', p))
      tests['ends with -']	= (lambda p: re.search('-$', p))
      for name in tests.keys():
        t = tests[name]
        if t(p):
          # print p + " did not pass: " + name
          return None
    # We have a good record!
    return recordData.lower()

# Validates the form of an MX record
class MXValidator(RecordValidator):
  ''' Validates the form of an MX record '''
  def __init__( self, state ):
    self.__state = state
  def validRecord( self, recordType, recordData, networkName = None ):
    # Eliminate trailing .
    pieces = recordData.split()
    if len( pieces ) != 2:
      return None
    prio = pieces[0]
    hostname = pieces[1]
    fqdnValidator = FQDNValidator( self.__state )
    if not( prio.isdigit() ):
      return None
    hostname = fqdnValidator.validRecord('fqdn', hostname, networkName)
    if not( hostname ):
      return None
    return '%s %s.' % ( prio, hostname )

# Validates the form of an MX record
class SRVValidator(RecordValidator):
  ''' Validates the form of an SRV record '''
  def __init__( self, state ):
    self.__state = state
  def validRecord( self, recordType, recordData, networkName = None ):
    # Eliminate trailing .
    pieces = recordData.split()
    if len( pieces ) != 4:
      return None
    prio = pieces[0]
    weight = pieces[1]
    port = pieces[2]
    hostname = pieces[3]
    fqdnValidator = FQDNValidator( self.__state )
    if not( prio.isdigit() ):
      return None
    hostname = fqdnValidator.validRecord('fqdn', hostname, networkName)
    if not( hostname ):
      return None
    return '%s %s.' % ( prio, hostname )

if __name__ == "__main__":
  print "Output below this line represents a failed test."
  addrt=(
	  ('a','192.168.1.1',			'',		'192.168.1.1'),
	  ('a','192.168.0.0',			'',		'192.168.0.0'),
	  ('a','192.168.000.000',		'',		'192.168.0.0'),
          # Don't go out of our way to support IPv4-Mapped IPv6 Address (RFC4291)
          ('a','::ffff:192.168.000.000',	'',		'192.168.0.0'),
          ('a','::ffff:192.168.0.0',		'',		'192.168.0.0'),
          # Don't go out of our way to support IPv4-Compatible IPv6 Address
	  # This is deprecated anyway and should not be used (RFC4291)
          # We'll accept the input as an IPv4 address (A record)
          ('a','::192.168.000.000',		'',		'192.168.0.0'),
          ('a','::192.168.0.0',			'',		'192.168.0.0'),
          # Test that bad addresses are rejected
          ('a','garbage.in.garbage.out',	'',		None),
          ('a','256.0.0.0',			'',		None),
          ('a','0.256.0.0',			'',		None),
          ('a','0.0.256.0',			'',		None),
          ('a','0.0.0.256',			'',		None),

	  # but not as an IPv6 address (AAAA record)
          ('aaaa','::192.168.000.000',		'',		None),
          ('aaaa','::192.168.0.0',		'',		None),
	  # But we will support both indirectly if the user really knows
	  # how to shoot themself in the foot
          ('aaaa','::ffff:c0a8:0000',		'',		'::ffff:c0a8:0'),
          ('aaaa','::ffff:c0a8:0',		'',		'::ffff:c0a8:0'),
          ('aaaa','::c0a8:0000',		'',		'::c0a8:0'),
          ('aaaa','::c0a8:0',			'',		'::c0a8:0'),
          # Normal IPv6 addresses should be returned correctly, let's try a few...
          ('aaaa','2607:f088:0:5:0:0:1:2',	'',		'2607:f088:0:5::1:2'),
          ('aaaa','2607:f088:0:5:0:1:2:3',	'',		'2607:f088::5:0:1:2:3'),
          # RFC 3056 addresses should work just like any other IPv6 address...
          ('aaaa','2002:0:0:5:0:0:1:2',		'',		'2002::5:0:0:1:2'),
          ('aaaa','2002:0:0:5:0:1:2:3',		'',		'2002::5:0:1:2:3'),
          # Test a few edge cases...
          ('aaaa','::',				'',		'::'),
          ('aaaa','::0',			'',		'::'),
          ('aaaa','0::0',			'',		'::'),
          ('aaaa','0::',			'',		'::'),
          ('aaaa','0::0:0',			'',		'::'),
          ('aaaa','0:0:0:0:0:0:0:0',		'',		'::'),
          ('aaaa','0::0::0',			'',		None),
          ('aaaa','::1',			'',		'::1'),

          ('cname','web-proxy.lpl.arizona.edu',	'',		'web-proxy.lpl.arizona.edu'),
          ('cname','web-proxy.lpl.arizona.edu.','',		'web-proxy.lpl.arizona.edu'),
          ('cname','-web.lpl.arizona.edu.',	'',		None),
          ('cname','web-.lpl.arizona.edu.',	'',		None),
          ('cname','0-0.lpl.arizona.edu.',	'',		'0-0.lpl.arizona.edu'),
          ('cname','-0.lpl.arizona.edu.',	'',		None),
          ('cname','0.lpl.arizona.edu.',	'',		None),
          ('cname','0a.lpl.arizona.edu.',	'',		'0a.lpl.arizona.edu'),

          ('mx','10 himail1.lpl.arizona.edu.',	'',		'10 himail1.lpl.arizona.edu.'),
          ('mx','10 himail1.lpl.arizona.edu',	'',		'10 himail1.lpl.arizona.edu.'),
          ('mx','10 hindmost.lpl.arizona.edu.',	'',		'10 hindmost.lpl.arizona.edu.'),
          ('mx','10 pirlserver.lpl.arizona.edu.','',		'10 pirlserver.lpl.arizona.edu.'),
          ('mx','10 vega.LPL.Arizona.EDU.',	'',		'10 vega.lpl.arizona.edu.'),
          ('mx','10 vega.LPL.Arizona.EDU',	'',		'10 vega.lpl.arizona.edu.'),
          ('mx','10 vega.lpl.arizona.edu.',	'',		'10 vega.lpl.arizona.edu.'),

  )
  validator = RecordValidator( None )
  for recordType,recordData,recordNetwork,expectedOutput in addrt:
    actualOutput = validator.validRecord( recordType, recordData, recordNetwork )
    if expectedOutput != actualOutput:
      print "%5s:%30s(%5s): %25s=%s" % (recordType, recordData, recordNetwork, expectedOutput, actualOutput)

