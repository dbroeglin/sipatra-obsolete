// ========================================================================
// Copyright 2003-2010 the original author or authors.
// ------------------------------------------------------------------------
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at 
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ========================================================================
package org.cipango.jruby;

import java.io.IOException;
import java.io.File;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;


import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.sip.SipServlet;
import javax.servlet.sip.SipServletMessage;
import javax.servlet.sip.SipServletRequest;
import javax.servlet.sip.SipServletResponse;

import org.jruby.embed.PathType;
import org.jruby.embed.ScriptingContainer;
import org.jruby.javasupport.JavaEmbedUtils.EvalUnit;

/**
 *
 */
public class JRubyServlet extends SipServlet //implements ResourceConnector
{
  private ScriptingContainer _container;
	private ServletContext _servletContext;
//  private EvalUnit _requestScript;
//  private EvalUnit _responseScript;

  /**
	 * Initialize the jrubyServlet.
	 * 
	 * @throws ServletException
	 *             if this method encountered difficulties
	 */
	@Override
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
    
    String classpath = getServletContext().getRealPath("/WEB-INF/jruby");
    List<String> loadPaths = new ArrayList<String>();
    
    loadPaths.add(classpath);    
    _container = new ScriptingContainer();
    _container.getProvider().setLoadPaths(loadPaths);
		_servletContext = config.getServletContext();
		
// 	_requestScript = _container.parse(getServletContext().getResourceAsStream("/WEB-INF/jruby/requests.rb"), "requests.rb");
// 	if (_requestScript == null) {
// 	  throw new ServletException("Unable to find '/WEB-INF/jruby/requests.rb'");
// 	}
// 	_responseScript = _container.parse(getServletContext().getResourceAsStream("/WEB-INF/jruby/responses.rb"), "responses.rb");
// 	if (_responseScript == null) {
// 	  throw new ServletException("Unable to find '/WEB-INF/jruby/responses.rb'"); 
// 	}
		
		// TODO: derive it from the servlets package name
		_container.runScriptlet(PathType.CLASSPATH, "/org/cipango/jruby/base.rb");
		_container.runScriptlet(PathType.ABSOLUTE, classpath + "/application.rb");
	}

	@Override
	public void doRequest(SipServletRequest request) throws IOException
	{
    _container.getVarMap().clear();
    setBindings(request);
    _container.put("@request", request);
    Map<String, Object> params = new LinkedHashMap<String, Object>();
		for (Enumeration names = request.getParameterNames(); names.hasMoreElements();)
		{
			String name = (String) names.nextElement();
			String[] values = request.getParameterValues(name);
			if (values.length == 1)
			{
				params.put(name, values[0]);
			}
			else
			{
				params.put(name, values);
			}
		}
		_container.put("@params", params);
    _container.runScriptlet("Sipatra::Application::new.do_request(@request)");
	}
	
	@Override
	public void doResponse(SipServletResponse response) throws IOException
	{
    _container.getVarMap().clear();
    setBindings(response);
    _container.put("@response", response);
    _container.runScriptlet("Sipatra::Application::new.do_response(@response)");
	}	
	
	private void setBindings(SipServletMessage message) {
    _container.put("@context", _servletContext);
    _container.put("@sipFactory", _servletContext.getAttribute(SipServlet.SIP_FACTORY));
    _container.put("@session", message.getSession());	  
	}
}
