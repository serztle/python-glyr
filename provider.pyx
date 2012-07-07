cimport glyr as C

"""
Here are no functions, classes, docstrings,
Just the Provider dictionary, looking like that:

   'albumlist': {
               'optional' : ('artist', 'album', 'title'),
               'required' : ('artist', 'album'),
               'provider' : {
                      'key'     : 'm',
                      'name'    : 'musicbrainz',
                      'quality' : 95,
                      'speed'   : 95
               } # next getter
   }

Note: This dictionary gets auto-generated on import
"""

PROVIDER = {}

# Build a dictionary structure of providers
cdef C.GlyrFetcherInfo * _head = C.glyr_info_get()
cdef C.GlyrFetcherInfo * _node = _head
cdef C.GlyrSourceInfo * _source = NULL

# This looks kinda stupid in a language like Python.
cdef make_requirement_tuple(C.GLYR_FIELD_REQUIREMENT reqs):
    rc = []
    if reqs & C.REQUIRES_ARTIST:
        rc.append('artist')
    if reqs & C.REQUIRES_ALBUM:
        rc.append('album')
    if reqs & C.REQUIRES_TITLE:
        rc.append('title')
    return tuple(rc)

# And it even gets sillier
cdef make_optional_tuple(C.GLYR_FIELD_REQUIREMENT reqs):
    rc = []
    if reqs & C.OPTIONAL_ARTIST:
        rc.append('artist')
    if reqs & C.OPTIONAL_ALBUM:
        rc.append('album')
    if reqs & C.OPTIONAL_TITLE:
        rc.append('title')
    return tuple(rc)

while _node is not NULL:
    _str_name = _stringify(_node.name)
    _source = _node.head
    PROVIDER[_str_name] = {}
    PROVIDER[_str_name]['optional'] = make_optional_tuple(_node.reqs)
    PROVIDER[_str_name]['required'] = make_requirement_tuple(_node.reqs)
    while _source is not NULL:
        PROVIDER[_str_name]['provider'] = {
                'name'   : _stringify(_source.name),
                'key'    : chr(_source.key),
                'quality': _source.quality,
                'speed'  : _source.speed,
        }
        _source = _source.next
    _node = _node.next

if _head is not NULL:
    C.glyr_info_free(_head)