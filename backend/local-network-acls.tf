locals {
  network_acls = {
    default_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = -1
        protocol    = "all"
        to_port     = -1
        cidr_block  = "0.0.0.0/0"
      }
    ]

    default_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = -1
        protocol    = "all"
        to_port     = -1
        cidr_block  = "0.0.0.0/0"
      }
    ]

    public_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = -1
        protocol    = "all"
        to_port     = -1
        cidr_block  = "0.0.0.0/0"
      }
    ]

    public_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = -1
        protocol    = "all"
        to_port     = -1
        cidr_block  = "0.0.0.0/0"
      }
    ]
  }
}