# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

# We have three types of constraint: location, order and colocation
# Each has a simple and complex form:
#
#   <rsc_location id="dont-run-apache-on-c001n03" rsc="myApacheRsc" score="-INFINITY" node="c001n03"/>
#
#   <rsc_location id="dont-run-apache-on-c001n03" rsc="myApacheRsc">
#     <rule id="dont-run-apache-rule" score="-INFINITY">
#        <expression id="dont-run-apache-expr" attribute="#uname" operation="eq" value="c00n03"/>
#     </rule>
#     <!-- more rules here -->
#   </rsc_location>
#
#   Or with resource sets:
#
#   <rsc_location id="on_node1" score="INFINITY" node="sles12-0">
#     <resource_set id="on_node1-0">
#       <resource_ref id="virtual-ip"/>
#       <resource_ref id="another-vip"/>
#     </resource_set>
#   </rsc_location>
#
#   <rsc_order id="order-2" first="IP" then="Webserver" score="0" symmetrical="true"/>
#
#   <rsc_order id="order-1">
#     <resource_set id="ordered-set-1" sequential="false">
#       <resource_ref id="A"/>
#       <resource_ref id="B"/>
#     </resource_set>
#     <resource_set id="ordered-set-2" sequential="false">
#       <resource_ref id="C"/>
#       <resource_ref id="D"/>
#     </resource_set>
#   </rsc_order>
#
#   Or, in future:
#
#   <rsc_order id="order-set" kind="Mandatory">
#     <ordering_set id="order-set-0" internal-ordering="Mandatory">
#       <resource_ref id="dummy0" role="Master"/>
#       <resource_ref id="dummy1" role="Master"/>
#     </ordering_set>
#     <ordering_set id="order-set-1" internal-ordering="Optional">
#       <resource_ref id="dummy2"/>
#       <resource_ref id="dummy3"/>
#     </ordering_set>
#   </rsc_order>
#
#   <rsc_colocation id="coloc-1" rsc="B" with-rsc="A" score="INFINITY"/>
#
#   <rsc_colocation id="coloc-1" score="INFINITY" >
#     <resource_set id="collocated-set-1" sequential="false">
#       <resource_ref id="A"/>
#       <resource_ref id="B"/>
#       <resource_ref id="C"/>
#     </resource_set>
#     <resource_set id="collocated-set-2" sequential="true">
#       <resource_ref id="D"/>
#     </resource_set>
#   </rsc_colocation>
#
#   Or, in future:
#
#    <rsc_colocation id="coloc-set" score="INFINITY">
#      <colocation_set id="coloc-set-1" internal-colocation="0">
#        <resource_ref id="dummy0" role="Master"/>
#        <resource_ref id="dummy1" role="Master"/>
#      </colocation_set>
#      <colocation_set id="coloc-set-0" internal-colocation="INFINITY">
#        <resource_ref id="dummy2"/>
#        <resource_ref id="dummy3"/>
#      </colocation_set>
#    </rsc_colocation>
class Constraint < Record
  class CommandError < StandardError
  end

  class << self
    def all
      super(true)
    end

    def cib_type_fetch
      :constraints
    end
  end
end
