// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
${fileheader}
// AUTOGENERATED. Do not edit this file by hand.
// See the hw/ip/otp_ctrl/data README for details.

#ifndef ${include_guard}
#define ${include_guard}

// See the following include file for details on the types used in this header
// file.
#include "sw/device/silicon_creator/manuf/lib/otp_img_types.h"

#include "otp_ctrl_regs.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

<%
  def ToPascalCase(in_str):
    '''Converts `in_str` from underscore to PascalCase format.'''
    out = ""
    upper = True
    for k in in_str.lower():
      if k == "_":
        upper = True
      else:
        out += k.upper() if upper else k
        upper = False
    return out

  def ToConstLabel(in_str):
    '''Returns `in_str` in PascalCase format with a "k" prefix.'''
    return "k" + ToPascalCase(in_str)

  def ToConstLabelValue(in_str):
    '''Returns `in_str` in PascalCase format with a "k" prefix and "Value" suffix.'''
    return f"{ToConstLabel(in_str)}Value"

  def _to_hex_array(values):
    '''Returns a C array initializer for a list of hex `values`.'''
    out = ["{"]

    # Print 4 numbers per line. This is why the step is set to 4 in the
    # iterator.
    if len(values) > 4:
      for i in range(0, len(values) - 4, 4):
        end = min(len(values), i + 4)
        out.append(", ".join(values[i:end]) + ",")
    else:
      out.append(", ".join(values))

    out.append("}")
    return "\n".join(out)

  def ConstTypeDefinition(item, alignment):
    '''Returns a C static const variable declaration for an `item`.

    Alignment must be either 4 (uint32_t), or 8 (uint64_t).
    '''
    type_str = None
    if alignment == 4:
      type_str = "uint32_t"
    elif alignment == 8:
      type_str = "uint64_t"
    else:
      raise f"Invalid alignment: {alignment}"

    base_declaration = f"static const {type_str} {ToConstLabelValue(item['name'])}"

    if item["num_items"] == 1:
      return f"{base_declaration} = {item['values'][0]};"
    else:
      return f"{base_declaration}[] = {_to_hex_array(item['values'])};"

  def RefValue(item, alignment):
    '''Returns a C reference to a pre-defined value for `item`.'''
    ref_name = None
    if alignment == 4:
      ref_name = ".value32"
    elif alignment == 8:
      ref_name = ".value64"
    else:
      raise f"Invalid alignment: {alignment}"

    if item["num_items"] == 1:
      return f"{ref_name} = &{ToConstLabelValue(item['name'])}"
    else:
      return f"{ref_name} = {ToConstLabelValue(item['name'])}"

  def ToOtpValType(alignment):
    '''Returns an `otp_val_type_t` enum value based on the struct alignment.'''
    if alignment == 4:
      return "kOptValTypeUint32Buff"
    elif alignment == 8:
      return "kOptValTypeUint64Buff"
    else:
      raise f"Invalid alignment: {alignment}"
%>

// OTP values
% for partition_name in data:
<%
  if len(data[partition_name]["items"]) == 0:
    continue
  alignment = data[partition_name]["alignment"]
%>
// Partition ${partition_name} values
% for item in data[partition_name]["items"]:
${ConstTypeDefinition(item, data[partition_name]["alignment"])}
% endfor
% endfor

// Partition definitions.

% for partition_name in data:
<%
  if len(data[partition_name]["items"]) == 0:
    continue
  alignment = data[partition_name]["alignment"]
%>
// Partition ${partition_name}
static otp_kv_t ${"kOtpKv" + ToPascalCase(partition_name)}[] = {
  % for item in data[partition_name]["items"]:
  {
    .type = ${ToOtpValType(alignment)},
    .offset = ${"OTP_CTRL_PARAM_" + item["name"] + "_OFFSET"},
    .num_values = ${int(item["num_items"])},
    ${RefValue(item, alignment)},
  },
  % endfor
};
% endfor


#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // ${include_guard}

