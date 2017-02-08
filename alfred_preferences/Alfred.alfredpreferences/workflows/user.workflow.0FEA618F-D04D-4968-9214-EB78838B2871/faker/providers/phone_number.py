# coding=utf-8

from __future__ import unicode_literals
from . import BaseProvider


class Provider(BaseProvider):
    formats = ('###-###-###',)

    @classmethod
    def phone_number(cls):
        return cls.numerify(cls.random_element(cls.formats))