$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'action_controller'
require 'action_controller/test_process'

require "ssl_requirement"

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true
ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil

class UrlRewriterTest < Test::Unit::TestCase
  def setup
    @request = ActionController::TestRequest.new
    @params = {}
    @rewriter = ActionController::UrlRewriter.new(@request, @params)

    @ssl_host_override = "www.example.com:80443"
    @non_ssl_host_override = "www.example.com:8080"

    SslRequirement.ssl_host = nil
    SslRequirement.non_ssl_host = nil
    
    # puts @url_rewriter.to_s
  end

  def test_rewrite_secure_false
    SslRequirement.disable_ssl_check = false
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false)
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false, 
                        :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false)
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => false,
                        :only_path => true)
    )
  end
  
  def test_rewrite_secure_true
    SslRequirement.disable_ssl_check = false
    assert_equal('https://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true)
    )
    assert_equal('https://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true, :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true)
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :secure => true, :only_path => true)
    )
  end
  
  def test_rewrite_secure_not_specified
    SslRequirement.disable_ssl_check = false
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a')
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :only_path => true)
    )
    
    SslRequirement.disable_ssl_check = true
    assert_equal('http://test.host/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a')
    )
    assert_equal('/c/a',
      @rewriter.rewrite(:controller => 'c', :action => 'a', :only_path => true)
    )
  end

  # tests for ssl_host overriding

  def test_rewrite_secure_with_ssl_host
    SslRequirement.disable_ssl_check = false
    SslRequirement.ssl_host = @ssl_host_override
    assert_equal("https://#{@ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :secure => true))
    assert_equal("https://#{@ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a',
                                   :secure => true, :only_path => true))
    SslRequirement.ssl_host = nil
  end

  def test_rewrite_non_secure_with_non_ssl_host
    SslRequirement.disable_ssl_check = false
    SslRequirement.non_ssl_host = @non_ssl_host_override

    # with secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a',
                                   :secure => false))
    assert_equal("/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :secure => false, :only_path => true))

    # without secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a'))
    assert_equal("/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :only_path => true))
    SslRequirement.non_ssl_host = nil
  end

  def test_rewrite_non_secure_with_non_ssl_host_disable_check
    SslRequirement.disable_ssl_check = true
    SslRequirement.non_ssl_host = @non_ssl_host_override

    # with secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a',
                                   :secure => false))
    assert_equal("/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :secure => false, :only_path => true))

    # without secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a'))
    assert_equal("/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :only_path => true))
    SslRequirement.non_ssl_host = nil
  end
  
  # tests for ssl_host overriding with Procs
  
  def test_rewrite_secure_with_ssl_host_proc
    SslRequirement.disable_ssl_check = false
    SslRequirement.ssl_host = Proc.new do
      @ssl_host_override
    end
    assert_equal("https://#{@ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a', 
                                   :secure => true))
    SslRequirement.ssl_host = nil
  end

  def test_rewrite_non_secure_with_non_ssl_host_proc
    SslRequirement.disable_ssl_check = false
    SslRequirement.non_ssl_host = Proc.new do
      @non_ssl_host_override
    end
    # with secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a',
                                   :secure => false))
    # without secure option
    assert_equal("http://#{@non_ssl_host_override}/c/a",
                 @rewriter.rewrite(:controller => 'c', :action => 'a'))
    SslRequirement.non_ssl_host = nil
  end
end
