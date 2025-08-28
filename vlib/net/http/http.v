// Copyright (c) 2019-2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module http

import net.urllib

const max_redirects = 16 // safari max - other browsers allow up to 20

const content_type_default = 'text/plain'

const bufsize = 64 * 1024

// get sends a GET HTTP request to the given `url`.
pub fn get(url string) !Response {
	return fetch(method: .get, url: url)
}

// post sends the string `data` as an HTTP POST request to the given `url`.
pub fn post(url string, data string) !Response {
	return fetch(
		method: .post
		url:    url
		data:   data
		header: new_header(key: .content_type, value: content_type_default)
	)
}

// post_json sends the JSON `data` as an HTTP POST request to the given `url`.
pub fn post_json(url string, data string) !Response {
	return fetch(
		method: .post
		url:    url
		data:   data
		header: new_header(key: .content_type, value: 'application/json')
	)
}

// post_form sends the map `data` as X-WWW-FORM-URLENCODED data to an HTTP POST request
// to the given `url`.
pub fn post_form(url string, data map[string]string) !Response {
	return fetch(
		method: .post
		url:    url
		header: new_header(key: .content_type, value: 'application/x-www-form-urlencoded')
		data:   url_encode_form_data(data)
	)
}

pub fn post_form_with_cookies(url string, data map[string]string, cookies map[string]string) !Response {
	return fetch(
		method:  .post
		url:     url
		header:  new_header(key: .content_type, value: 'application/x-www-form-urlencoded')
		data:    url_encode_form_data(data)
		cookies: cookies
	)
}

@[params]
pub struct PostMultipartFormConfig {
pub mut:
	form   map[string]string
	files  map[string][]FileData
	header Header
}

// post_multipart_form sends multipart form data `conf` as an HTTP POST
// request to the given `url`.
pub fn post_multipart_form(url string, conf PostMultipartFormConfig) !Response {
	body, boundary := multipart_form_body(conf.form, conf.files)
	mut header := conf.header
	header.set(.content_type, 'multipart/form-data; boundary="${boundary}"')
	return fetch(
		method: .post
		url:    url
		header: header
		data:   body
	)
}

// put sends string `data` as an HTTP PUT request to the given `url`.
pub fn put(url string, data string) !Response {
	return fetch(
		method: .put
		url:    url
		data:   data
		header: new_header(key: .content_type, value: content_type_default)
	)
}

// patch sends string `data` as an HTTP PATCH request to the given `url`.
pub fn patch(url string, data string) !Response {
	return fetch(
		method: .patch
		url:    url
		data:   data
		header: new_header(key: .content_type, value: content_type_default)
	)
}

// head sends an HTTP HEAD request to the given `url`.
pub fn head(url string) !Response {
	return fetch(method: .head, url: url)
}

// delete sends an HTTP DELETE request to the given `url`.
pub fn delete(url string) !Response {
	return fetch(method: .delete, url: url)
}

// TODO: @[noinline] attribute is used for temporary fix the 'get_text()' intermittent segfault / nil value when compiling with GCC 13.2.x and -prod option ( Issue #20506 )
// fetch sends an HTTP request to the `url` with the given method and configuration.
@[noinline]
pub fn fetch(mut config Request) !Response {
	mut req := prepare(mut config)!
	return req.do()!
}

// get_text sends an HTTP GET request to the given `url` and returns the text content of the response.
pub fn get_text(url string) string {
	resp := fetch(url: url, method: .get) or { return '' }
	return resp.body
}

// url_encode_form_data converts mapped data to a URL encoded string.
pub fn url_encode_form_data(data map[string]string) string {
	mut pieces := []string{}
	for key_, value_ in data {
		key := urllib.query_escape(key_)
		value := urllib.query_escape(value_)
		pieces << '${key}=${value}'
	}
	return pieces.join('&')
}
