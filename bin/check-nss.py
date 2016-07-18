#!/usr/bin/env python
import os
import pwd
print pwd.getpwuid(os.getuid())
