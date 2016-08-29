# Adapted from https://gist.github.com/nickyp/886884.

require 'rubygems'
require 'openssl'

certd = File.join( File.dirname( __FILE__ ), 'ssl.pem' )
keyd  = File.join( File.dirname( __FILE__ ), 'ssl.key' )

key = OpenSSL::PKey::RSA.new(2048)
public_key = key.public_key

subject = "/C=BE/O=127.0.0.1/OU=127.0.0.1/CN=127.0.0.1"

cert = OpenSSL::X509::Certificate.new
cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
cert.not_before = Time.now
cert.not_after = Time.now + 365 * 24 * 60 * 60 * 99
cert.public_key = public_key
cert.serial = 0x0
cert.version = 2

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = cert
ef.issuer_certificate = cert
cert.extensions = [
  ef.create_extension("basicConstraints","CA:TRUE", true),
  ef.create_extension("subjectKeyIdentifier", "hash"),
]
cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                       "keyid:always,issuer:always")

cert.sign key, OpenSSL::Digest::SHA256.new

open  keyd, 'w' do |io| io.write  key.to_pem end
open certd, 'w' do |io| io.write cert.to_pem end

puts "OK"
