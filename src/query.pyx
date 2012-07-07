cimport glyr as C

from cpython cimport bool

include "cache.pyx"

# This is a proxy callback that reads a PyObject from
# a user_pointer and calls it
cdef int _actual_callback(C.GlyrMemCache * c, C.GlyrQuery * q):
    'Proxy callback, calling set callable object, and returning rc to C-Side'
    py_callback = <object>q.callback.user_pointer
    return py_callback(1, 2)


cdef query_from_pointer(C.GlyrQuery * query):
    pyq = Query(new_query=False)
    pyq._cqp = query
    return pyq


cdef class Query:
    """
    A Query is an object defining a search term for libglyr.
    As a minimum the ,,get_type'' and ,,artist'' and/or the
    ,,album'' or ,,title'' properties shall be set.

    The constructor takes a list of keywords, these keywords
    are the same as the propertynames below.

    A Query can be committed with commit(), which blocks till
    execution is done. On the way a callback method may be
    called as set by the equally named property. One may cancel
    a Query from another thread by calling cancel() on it,
    or returning a value other than 0 from the callback.
    """
    # Actual underlying Query
    cdef C.GlyrQuery _cq
    cdef C.GlyrQuery * _cqp

    # Allocation on C-Side
    def __cinit__(self, new_query=True, **kwargs):
        if new_query:
            C.glyr_query_init(&self._cq)
            self._cqp = &self._cq

            for key, value in kwargs.items():
                Query.__dict__[key].__set__(self, value)

    cdef C.GlyrQuery * _ptr(self):
        return self._cqp

    # Deallocation on C-Side
    def __dealloc__(self):
        C.glyr_query_destroy(self._cqp)
        self._cqp = NULL

    ###########################################################################
    #         Lots of properties, these wrap the glyr_opt_* family()          #
    ###########################################################################

    property get_type:
        def __set__(self, value):
            if type(value) is str:
                byte_value = _bytify(value)
                actual_type = C.glyr_string_to_get_type(byte_value)
            else:
                actual_type = value

            C.glyr_opt_type(self._cqp, actual_type)
        def __get__(self):
            return _stringify(C.glyr_get_type_to_string(self._cqp.type))

    property number:
        def __set__(self, int number):
            C.glyr_opt_number(self._cqp, number)
        def __get__(self):
            return self._cqp.number

    property max_per_plugins:
        def __set__(self, int max_per_plugins):
            C.glyr_opt_plugmax(self._cqp, max_per_plugins)
        def __get__(self):
            return self._cqp.plugmax

    property verbosity:
        def __set__(self, int verbosity):
            C.glyr_opt_verbosity(self._cqp, verbosity)
        def __get__(self):
            return self._cqp.verbosity

    property fuzzyness:
        def __set__(self, int fuzzyness):
            C.glyr_opt_fuzzyness(self._cqp, fuzzyness)
        def __get__(self):
            return self._cqp.fuzzyness

    property img_size:
        def __set__(self, size_tuple):
            C.glyr_opt_img_minsize(self._cqp, size_tuple[0])
            C.glyr_opt_img_maxsize(self._cqp, size_tuple[1])
        def __get__(self):
            return [self._cqp.img_max_size, self._cqp.img_min_size]

    property parallel:
        def __set__(self, int parallel):
            C.glyr_opt_parallel(self._cqp, parallel)
        def __get__(self):
            return self._cqp.parallel

    property timeout:
        def __set__(self, int timeout):
            C.glyr_opt_timeout(self._cqp, timeout)
        def __get__(self):
            return self._cqp.timeout

    property redirects:
        def __set__(self, int redirects):
            C.glyr_opt_redirects(self._cqp, redirects)
        def __get__(self):
            return self._cqp.redirects

    property force_utf8:
        def __set__(self, bool force_utf8):
            C.glyr_opt_force_utf8(self._cqp, force_utf8)
        def __get__(self):
            return self._cqp.force_utf8

    property qsratio:
        def __set__(self, float qsratio):
            C.glyr_opt_qsratio(self._cqp, qsratio)
        def __get__(self):
            return self._cqp.qsratio

    property db_autoread:
        def __set__(self, bool db_autoread):
            C.glyr_opt_db_autoread(self._cqp, db_autoread)
        def __get__(self):
            return self._cqp.db_autoread

    property db_autowrite:
        def __set__(self, bool db_autowrite):
            C.glyr_opt_db_autowrite(self._cqp, db_autowrite)
        def __get__(self):
            return self._cqp.db_autowrite

    property database:
        def __set__(self, Database database):
            C.glyr_opt_lookup_db(self._cqp, database._cdb)
        def __get__(self):
            db = Database()
            db._cdb = self._cqp.local_db
            return db

    property lang_aware_only:
        def __set__(self, bool lang_aware_only):
            C.glyr_opt_lang_aware_only(self._cqp, lang_aware_only)
        def __get__(self):
            return self._cqp.lang_aware_only

    property language:
        def __set__(self, language):
            C.glyr_opt_lang(self._cqp, language)
        def __get__(self):
            return self._cqp.lang

    property proxy:
        def __set__(self, proxy):
            C.glyr_opt_proxy(self._cqp, proxy)
        def __get__(self):
            return self._cqp.proxy

    property artist:
        def __set__(self, value):
            byte_value = _bytify(value)
            C.glyr_opt_artist(self._cqp, byte_value)
        def __get__(self):
            return _stringify(self._cqp.artist)

    property album:
        def __set__(self, value):
            byte_value = _bytify(value)
            C.glyr_opt_album(self._cqp, byte_value)
        def __get__(self):
            return _stringify(self._cqp.album)

    property title:
        def __set__(self, value):
            byte_value = _bytify(value)
            C.glyr_opt_title(self._cqp, byte_value)
        def __get__(self):
            return _stringify(self._cqp.title)

    property providers:
        def __set__(self, value_list):
            provider_string = _bytify(';'.join(value_list))
            C.glyr_opt_from(self._cqp, provider_string)
        def __get__(self):
            return _stringify(self._cqp.providers).split(';')

    property callback:
        # Save callable object as user_pointer
        # just cast it back if you do __get__
        def __set__(self, object py_func):
            C.glyr_opt_dlcallback(self._cqp, <C.DL_callback>_actual_callback, <void*>py_func)
        def __get__(self):
            return <object>self._cqp.callback.user_pointer

    property allowed_formats:
        def __set__(self,  allowed_formats):
            allowed_list = _bytify(';'.join(allowed_formats))
            C.glyr_opt_allowed_formats(self._cqp, allowed_list)
        def __get__(self):
            return _stringify(self._cqp.allowed_formats).split(';')

    property useragent:
        def __set__(self,  useragent):
            C.glyr_opt_useragent(self._cqp, useragent)
        def __get__(self):
            return self._cqp.useragent

    property musictree_path:
        def __set__(self,  musictree_path):
            C.glyr_opt_musictree_path(self._cqp, musictree_path)
        def __get__(self):
            return self._cqp.musictree_path

    ###########################################################################
    #                              other methods                              #
    ###########################################################################

    def commit(self):
        """
        Commit a configured Query.
        This function blocks until execution is done.

        :returns: a list of byteblobs or [] on error,
                  use error to find out what happened.
        """
        item_list = C.glyr_get(self._cqp, NULL, NULL)
        return cache_list_from_pointer(item_list)

    def cancel(self):
        """
        Stop an already started query from another thread.
        Note: This does not make commit() return immediately, it's rather a
              soft shutdown that finishes already running parsers, but do
              not download any new data.
        """
        C.glyr_signal_exit(self._cqp)

    property error:
        'String representation of internally happened error (might be "No Error")'
        def __get__(self):
            return _stringify(C.glyr_strerror(self._cqp.q_errno))
