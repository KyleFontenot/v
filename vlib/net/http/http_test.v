module http

// import net.http
import net.urllib

fn test_http_get() {
	$if !network ? {
		return
	}
	assert get_text('https://vlang.io/version') == '0.1.5'
	println('http ok')
}

fn test_http_get_from_vlang_utc_now() {
	$if !network ? {
		return
	}
	urls := ['http://vlang.io/utc_now', 'https://vlang.io/utc_now']
	for url in urls {
		println('Test getting current time from ${url} by http.get')
		res := get(url) or { panic(err) }
		assert res.status() == .ok
		assert res.body != ''
		assert res.body.int() > 1566403696
		println('Current time is: ${res.body.int()}')
	}
}

fn test_public_servers() {
	$if !network ? {
		return
	}
	urls := [
		'http://github.com/robots.txt',
		'http://google.com/robots.txt',
		'https://github.com/robots.txt',
		'https://google.com/robots.txt',
		// 'http://yahoo.com/robots.txt',
		// 'https://yahoo.com/robots.txt',
	]
	for url in urls {
		println('Testing http.get on public url: ${url} ')
		res := get(url) or { panic(err) }
		assert res.status() == .ok
		assert res.body != ''
	}
}

fn test_relative_redirects() {
	$if !network ? {
		return
	} $else {
		return
	} // tempfix periodic: httpbin relative redirects are broken
	res := get('https://httpbin.org/relative-redirect/3?abc=xyz') or { panic(err) }
	assert res.status() == .ok
	assert res.body != ''
	assert res.body.contains('"abc": "xyz"')
}

fn test_fetch_with_request_params() {
	$if !network ? {
		return
	}

	test_request := Request{
		url:     urllib.parse('http://vlang.io/utc_now?abc=xyz')!
		headers: new_header(
			key:   .keep_alive
			value: '1'
		)
	}
	test_request.prepare() or {}
	assert test_request.headers.get(.keep_alive) == '1'
	assert test_request.url is urllib.URL
	assert test_request.url.params.get('abc') == 'xyz'
	// assert test_request.url.raw_query == '/utc_now'
	println(test_request.url.debug())

	// The url string should re-parse and overwrite the url field made in the request above.
	res := get('http://vlang.io/utc_now', test_request)

	assert res.status_code == 200
	assert res.body != ''
}
