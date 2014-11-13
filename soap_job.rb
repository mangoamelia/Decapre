require 'savon' # Use version 2.0 Savon gem
require 'date'

class MarketoSoapSignupJob

  @queue = :marketo

  def self.add_signup(cookie, email)
    Resque.enqueue(self, cookie, email)
  end

  def self.perform(cookie, email)

    mktowsUserId = @soap_credentials[:user_id]
    marketoSecretKey = @soap_credentials[:secret_key]
    marketoSoapEndPoint = @soap_credentials[:soap_endpoint]
    marketoNameSpace = @soap_credentials[:name_space]

    #Create Signature
    timestamp = DateTime.now
    requestTimestamp = timestamp.to_s
    encryptString = requestTimestamp + mktowsUserId
    digest = OpenSSL::Digest.new('sha1')
    hashedsignature = OpenSSL::HMAC.hexdigest(digest, marketoSecretKey, encryptString)
    requestSignature = hashedsignature.to_s

    #Create SOAP Header
    headers = { 
      'ns1:AuthenticationHeader' => { 
        "mktowsUserId" => mktowsUserId,
        "requestSignature" => requestSignature,
        "requestTimestamp"  => requestTimestamp 
      }
    }

    client = Savon.client(
      wsdl: 'http://app.marketo.com/soap/mktows/2_3?WSDL', 
      soap_header: headers,
      endpoint: marketoSoapEndPoint,
      open_timeout: 90,
      read_timeout: 90,
      namespace_identifier: :ns1,
      env_namespace: 'SOAP-ENV'
    )

    #Create Request
    request = {
      :lead_record => {
        :Email => email,
        },
      :marketoCookie => cookie,
      :return_lead => "false"
    }
    
    response = client.call(:sync_lead, message: request)


  end

  def self.credentials=(cred)
    @soap_credentials = cred
  end

end