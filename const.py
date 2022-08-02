"""
Module to implement constant like class.
Courtesy: http://code.activestate.com/recipes/65207-constants-in-python/
"""
class _const:
    class ConstError(TypeError): pass

    def __setattr__(self, name, value):
        if name in self.__dict__:
            raise(self.ConstError, "Can't rebind const(%s)" %name)
        self.__dict__[name] = value

import sys
sys.modules[__name__] = _const()
