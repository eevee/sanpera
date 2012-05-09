"""py.test configuration for this module.

Every Usage test function defines a `ctx` argument (short for 'context'), which
is a little helper object.  This file contains the py.test hook for creating
that helper object.
"""

import operator

from sanpera.tests.im_usage.common import UsageContext

def pytest_funcarg__ctx(request):
    # Create a context object.  This caching ensures that the same object is
    # used for every test in a module, so that they all share one output
    # directory -- some tests use the results of previous tests.
    ctx = request.cached_setup(UsageContext, operator.methodcaller('destroy'), scope='module')
    ctx.do_convert(request.function)
    return ctx
