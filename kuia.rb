# ObjC and Cocoa modules taked from http://spin.atomicobject.com/2013/02/15/ffi-foreign-function-interfaces/
# Thanks John Croisant

# Load the 'ffi' gem.
$LOAD_PATH.unshift '/Library/Ruby/Gems/1.8/gems/ffi-1.9.3/lib'
require 'ffi'
 
module ObjC
  extend FFI::Library
 
  # Load the 'libobjc' library.
  ffi_lib 'objc'
 
  # Bind the 'sel_registerName' function, which accepts a String and
  # returns an equivalent Objective-C selector (i.e. message name).
  attach_function :sel_registerName, [:string], :pointer
 
  # Bind the 'objc_msgSend' function, which sends a message to an
  # Objective-C object. It accepts a pointer to the object being sent
  # the message, a pointer to a selector, and a varargs array of
  # arguments to be sent with the message. It returns a pointer to the
  # result of sending the message.
  attach_function :objc_msgSend, [:pointer, :pointer, :varargs], :pointer
 
  # A convenience method using objc_msgSend and sel_registerName to easily
  # send Objective-C messages from Ruby.
  def self.msgSend( id, selector, *args )
    selector = sel_registerName(selector) if selector.is_a? String
    return objc_msgSend( id, selector, *args )
  end
 
  # Bind the 'objc_getClass' function, which accepts the name of an
  # Objective-C class, and returns a pointer to that class.
  attach_function :objc_getClass, [:string], :pointer
end
 
 
module Cocoa
  extend FFI::Library
 
  # Load the Cocoa framework's binary code
  ffi_lib '/System/Library/Frameworks/Cocoa.framework/Cocoa'
 
  # Needed to properly set up the Objective-C environment.
  attach_function :NSApplicationLoad, [], :bool
  NSApplicationLoad()
 
  # Accepts a Ruby String and creates an equivalent NSString instance
  # and returns a pointer to it.
  def self.StringToNSString( string )
    nsstring_class = ObjC.objc_getClass("NSString")
    ObjC.msgSend( nsstring_class, "stringWithUTF8String:",
                  :string, string )
  end
 
  # Accepts a pointer to an NSString object, and returns the string
  # contents as a Ruby String.
  def self.NSStringToString( nsstring_pointer )
    c_string_pointer = ObjC.msgSend( nsstring_pointer, "UTF8String" )
    if c_string_pointer.null?
      return "(NULL)"
    else
      return c_string_pointer.read_string()
    end
  end

  def self.numberToNSNumber(number)
    nsNumberClass = ObjC.objc_getClass("NSNumber")
    return ObjC.msgSend(nsNumberClass, 'numberWithInt:', :int, number)
  end

  def self.rubyObjectToCocoaObject(object)
    if object.instance_of?(TrueClass) || object.instance_of?(FalseClass)
        return self.numberToNSNumber((object ? 1 : 0))
    elsif object.instance_of? Fixnum
      return self.numberToNSNumber(object)
    elsif object.instance_of? String
      return self.StringToNSString(object)
    end
    return object
  end

  def self.hashToNSDictionary(hash)
    dictionaryClass = ObjC.objc_getClass("NSMutableDictionary")
    dictionary = ObjC.msgSend(dictionaryClass, 'dictionary')    
    hash.each do |key,value|
      ObjC.msgSend(dictionary, 'setObject:forKey:', :pointer, Cocoa.rubyObjectToCocoaObject(value), :pointer, Cocoa.rubyObjectToCocoaObject(key))
    end
    return dictionary
  end

end

module KUElement
  extend FFI::Library

  # Load the library
  ffi_lib File.expand_path('../kuia.dylib', __FILE__)

  def self.getAppElement(pid)
    kuElementClass = ObjC.objc_getClass("KUElement")
    return ObjC.msgSend(kuElementClass,'appElementForPID:', :int, pid)
  end

  def self.getAppElementByPath(path,launch)
    kuElementClass = ObjC.objc_getClass("KUElement")
return ObjC.msgSend(kuElementClass,'appElementForPath:launchIfNotRunning:', :pointer, Cocoa.StringToNSString(path), :bool, launch)
  end

  def self.query(element, queryDict)
    return ObjC.msgSend(element,'query:', :pointer, Cocoa.hashToNSDictionary(queryDict))
  end

  def self.queryOne(element, queryDict)
#puts caller
    return ObjC.msgSend(element,'queryOne:', :pointer, Cocoa.hashToNSDictionary(queryDict))
  end

  def self.performAction(element, action)
    ObjC.msgSend(element,'performAction:', :pointer, Cocoa.StringToNSString(action))
  end

  def self.postKeyboardEvent(element, keyChar, virtualKey, keyDown)
    ObjC.msgSend(element,'postKeyboardEvent:virtualKey:keyDown:', :int, keyChar, :int, virtualKey, :bool, keyDown)
  end

  def self.typeCharacter(element, chr)
    ObjC.msgSend(element,'typeCharacter:', :int, chr)
  end

  def self.changeAttribute(element, attribute, value)
    ObjC.msgSend(element,'changeAttribute:to:', :pointer, Cocoa.rubyObjectToCocoaObject(attribute), :pointer, Cocoa.rubyObjectToCocoaObject(value))
  end
end
