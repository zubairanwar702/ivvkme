using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Nop.Web.Models.Customer
{
    public class PhoneVerificationModel
    {
        public long Id { set; get; }
        public string PhoneNumber { set; get; }
        public string Code { set; get; }

        public bool IsVerified { set; get; }
    }
}
