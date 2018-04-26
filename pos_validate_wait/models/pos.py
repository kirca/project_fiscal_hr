
from openerp import models
import time


class POS(models.Model):
    _inherit = 'pos.order'

    def create_from_ui(self, cr, uid, orders, context=None):
        time.sleep(10)
        return super(POS, self).create_from_ui(cr, uid, orders, context=context)
