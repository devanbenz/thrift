/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#include "thrift/generate/t_zig_generator.h"
#include "thrift/platform.h"
#include "thrift/version.h"

#include <algorithm>
#include <cassert>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

using std::map;
using std::ofstream;
using std::ostringstream;
using std::set;
using std::string;
using std::vector;

// Zig reserved words that cannot be used as identifiers
const set<string> t_zig_generator::zig_reserved_words_ = {
    "align", "allowzero", "and", "asm", "async", "await", "break", "catch", "comptime", "const",
    "continue", "defer", "else", "enum", "errdefer", "error", "export", "extern", "false", "fn",
    "for", "if", "inline", "noalias", "null", "or", "packed", "pub", "resume", "return", "struct",
    "suspend", "switch", "test", "threadlocal", "true", "try", "undefined", "union", "unreachable",
    "usingnamespace", "var", "volatile", "while", "anyframe", "anytype", "callconv", "noreturn",
    "nosuspend", "noinline", "opaque", "linksection", "addrspace"
};

/**
 * Constructor - parse options and initialize generator
 */
t_zig_generator::t_zig_generator(t_program* program, 
                                 const map<string, string>& options,
                                 const string& /* option_string */)
    : t_generator(program) {
    
    gen_dir_ = get_out_dir();
    
    // Parse generator options
    for (const auto& option : options) {
        if (option.first == "package") {
            options_.package_name = option.second;
        } else if (option.first == "allocator") {
            options_.allocator_type = option.second;
        } else if (option.first == "async") {
            options_.generate_async = (option.second == "true" || option.second == "1");
        } else if (option.first == "comptime") {
            options_.generate_comptime = (option.second == "true" || option.second == "1");
        } else if (option.first == "tests") {
            options_.generate_tests = (option.second == "true" || option.second == "1");
        } else if (option.first == "packed") {
            options_.use_packed_structs = (option.second == "true" || option.second == "1");
        } else if (option.first == "format") {
            options_.output_format = option.second;
        }
    }
    
    out_dir_base_ = "gen-zig";
}

/**
 * Initialize the generator
 */
void t_zig_generator::init_generator() {
    // Create output directory if it doesn't exist
    MKDIR(gen_dir_.c_str());
    
    // Open the output file
    string f_name = gen_dir_ + program_name_ + ".zig";
    f_gen_.open(f_name.c_str());
    
    // Generate file header
    generate_file_header();
    generate_imports();
    generate_common_types();
}

/**
 * Finalize the generator
 */
void t_zig_generator::close_generator() {
    if (options_.generate_tests) {
        f_gen_ << "\n// Tests\n";
        f_gen_ << "const testing = std.testing;\n";
        f_gen_ << "const expect = testing.expect;\n";
        f_gen_ << "const expectEqual = testing.expectEqual;\n";
        f_gen_ << "const expectEqualSlices = testing.expectEqualSlices;\n\n";
    }
    
    f_gen_.close();
}

/**
 * Display name for the generator
 */
string t_zig_generator::display_name() const {
    return "Zig";
}

/**
 * Generate file header with license and imports
 */
void t_zig_generator::generate_file_header() {
    f_gen_ << zig_autogen_comment();
    f_gen_ << "const std = @import(\"std\");\n";
    f_gen_ << "const thrift = @import(\"thrift\");\n";
    f_gen_ << "const Protocol = thrift.Protocol;\n";
    f_gen_ << "const ProtocolError = thrift.ProtocolError;\n";
    f_gen_ << "const FieldType = thrift.FieldType;\n";
    f_gen_ << "const MessageType = thrift.MessageType;\n";
    f_gen_ << "const TransportError = thrift.TransportError;\n\n";
}

/**
 * Generate common imports and type definitions
 */
void t_zig_generator::generate_imports() {
    f_gen_ << "// Common types and utilities\n";
    f_gen_ << "const ArrayList = std.ArrayList;\n";
    f_gen_ << "const HashMap = std.HashMap;\n";
    f_gen_ << "const HashSet = std.HashSet;\n";
    f_gen_ << "const Allocator = std.mem.Allocator;\n\n";
}

/**
 * Generate common type definitions
 */
void t_zig_generator::generate_common_types() {
    f_gen_ << "// Common error types\n";
    f_gen_ << "pub const ThriftError = error{\n";
    f_gen_ << "    ProtocolError,\n";
    f_gen_ << "    TransportError,\n";
    f_gen_ << "    ApplicationError,\n";
    f_gen_ << "    FieldNotFound,\n";
    f_gen_ << "    TypeMismatch,\n";
    f_gen_ << "    OutOfMemory,\n";
    f_gen_ << "    InvalidData,\n";
    f_gen_ << "};\n\n";
}

/**
 * Generate autogenerated comment
 */
string t_zig_generator::zig_autogen_comment() {
    return "//!\n"
           "//! Autogenerated by Thrift Compiler (" + string(THRIFT_VERSION) + ")\n"
           "//!\n"
           "//! DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING\n"
           "//!  @generated\n"
           "//!\n\n";
}

/**
 * Get Zig keywords for validation
 */
set<string> t_zig_generator::lang_keywords_for_validation() const {
    return zig_reserved_words_;
}

/**
 * Check if a word is a Zig reserved word
 */
bool t_zig_generator::is_zig_reserved_word(const string& name) {
    return zig_reserved_words_.find(name) != zig_reserved_words_.end();
}

/**
 * Sanitize identifier to avoid conflicts with Zig keywords
 */
string t_zig_generator::zig_sanitize_identifier(const string& name) {
    if (is_zig_reserved_word(name)) {
        return "@\"" + name + "\"";
    }
    return name;
}

/**
 * Generate typedef
 */
void t_zig_generator::generate_typedef(t_typedef* ttypedef) {
    f_gen_ << "pub const " << zig_sanitize_identifier(ttypedef->get_name()) 
           << " = " << to_zig_type(ttypedef->get_type()) << ";\n\n";
}

/**
 * Generate enum
 */
void t_zig_generator::generate_enum(t_enum* tenum) {
    f_gen_ << "pub const " << zig_enum_name(tenum) << " = enum(i32) {\n";
    
    const vector<t_enum_value*>& constants = tenum->get_constants();
    for (auto const_iter : constants) {
        f_gen_ << "    " << zig_sanitize_identifier(const_iter->get_name());
        if (const_iter->get_value() != 0) {
            f_gen_ << " = " << const_iter->get_value();
        }
        f_gen_ << ",\n";
    }
    
    f_gen_ << "};\n\n";
}

/**
 * Generate constant
 */
void t_zig_generator::generate_const(t_const* tconst) {
    f_gen_ << "pub const " << zig_const_name(tconst) 
           << ": " << to_zig_type(tconst->get_type())
           << " = " << to_zig_const_value(tconst->get_value(), tconst->get_type()) << ";\n\n";
}

/**
 * Generate struct - main entry point for struct generation
 */
void t_zig_generator::generate_struct(t_struct* tstruct) {
    generate_struct_definition(tstruct, STRUCT_REGULAR);
}

/**
 * Generate exception (same as struct in Zig)
 */
void t_zig_generator::generate_xception(t_struct* txception) {
    generate_struct_definition(txception, STRUCT_EXCEPTION);
}

/**
 * Generate service
 */
void t_zig_generator::generate_service(t_service* tservice) {
    string service_name = zig_service_name(tservice);
    
    f_gen_ << "pub const " << service_name << " = struct {\n";
    f_gen_ << "    const Self = @This();\n\n";
    
    // Generate service methods
    const vector<t_function*>& functions = tservice->get_functions();
    for (auto func : functions) {
        generate_service_method(func, options_.generate_async);
    }
    
    f_gen_ << "};\n\n";
    
    // Generate client and server stubs
    generate_service_client(tservice);
    generate_service_server(tservice);
}

/**
 * Generate service method
 */
void t_zig_generator::generate_service_method(t_function* tfunction, bool is_async) {
    string method_name = zig_function_name(tfunction);
    string return_type = to_zig_type(tfunction->get_returntype());
    
    f_gen_ << "    pub fn " << method_name << "(";
    
    // Generate parameters
    const vector<t_field*>& args = tfunction->get_arglist()->get_members();
    bool first = true;
    for (auto arg : args) {
        if (!first) f_gen_ << ", ";
        first = false;
        f_gen_ << zig_field_name(arg) << ": " << to_zig_type(arg->get_type());
    }
    
    f_gen_ << ") ";
    
    // Add async if needed
    if (is_async) {
        f_gen_ << "async ";
    }
    
    // Add error handling
    f_gen_ << "ThriftError!";
    
    // Add return type
    if (!tfunction->get_returntype()->is_void()) {
        f_gen_ << return_type;
    } else {
        f_gen_ << "void";
    }
    
    f_gen_ << " {\n";
    f_gen_ << "        // Method implementation (to be provided by user)\n";
    
    // Add parameter usage to avoid unused variable warnings
    for (auto arg : args) {
        f_gen_ << "        _ = " << zig_field_name(arg) << ";\n";
    }
    
    f_gen_ << "        return error.NotImplemented;\n";
    f_gen_ << "    }\n\n";
}

/**
 * Generate service client
 */
void t_zig_generator::generate_service_client(t_service* tservice) {
    string service_name = zig_service_name(tservice);
    
    f_gen_ << "pub const " << service_name << "Client = struct {\n";
    f_gen_ << "    protocol: *Protocol,\n";
    f_gen_ << "    const Self = @This();\n\n";
    
    f_gen_ << "    pub fn init(protocol: *Protocol) Self {\n";
    f_gen_ << "        return Self{ .protocol = protocol };\n";
    f_gen_ << "    }\n\n";
    
    // Generate client methods
    const vector<t_function*>& functions = tservice->get_functions();
    for (auto func : functions) {
        string method_name = zig_function_name(func);
        string return_type = to_zig_type(func->get_returntype());
        
        f_gen_ << "    pub fn " << method_name << "(self: *Self";
        
        const vector<t_field*>& args = func->get_arglist()->get_members();
        for (auto arg : args) {
            f_gen_ << ", " << zig_field_name(arg) << ": " << to_zig_type(arg->get_type());
        }
        
        f_gen_ << ") ThriftError!";
        
        if (!func->get_returntype()->is_void()) {
            f_gen_ << return_type;
        } else {
            f_gen_ << "void";
        }
        
        f_gen_ << " {\n";
        f_gen_ << "        // Client method implementation (to be completed)\n";
        f_gen_ << "        _ = self;\n";
        
        // Add parameter usage to avoid unused variable warnings
        for (auto arg : args) {
            f_gen_ << "        _ = " << zig_field_name(arg) << ";\n";
        }
        
        f_gen_ << "        return error.NotImplemented;\n";
        f_gen_ << "    }\n\n";
    }
    
    f_gen_ << "};\n\n";
}

/**
 * Generate service server
 */
void t_zig_generator::generate_service_server(t_service* tservice) {
    string service_name = zig_service_name(tservice);
    
    f_gen_ << "pub const " << service_name << "Server = struct {\n";
    f_gen_ << "    handler: *" << service_name << ",\n";
    f_gen_ << "    const Self = @This();\n\n";
    
    f_gen_ << "    pub fn init(handler: *" << service_name << ") Self {\n";
    f_gen_ << "        return Self{ .handler = handler };\n";
    f_gen_ << "    }\n\n";
    
    f_gen_ << "    pub fn process(self: *Self, protocol: *Protocol) ThriftError!void {\n";
    f_gen_ << "        // Server processing implementation (to be completed)\n";
    f_gen_ << "        _ = self;\n";
    f_gen_ << "        _ = protocol;\n";
    f_gen_ << "        return error.NotImplemented;\n";
    f_gen_ << "    }\n\n";
    
    f_gen_ << "};\n\n";
}

/**
 * Name conversion utilities
 */
string t_zig_generator::zig_struct_name(t_struct* tstruct) {
    return zig_sanitize_identifier(tstruct->get_name());
}

string t_zig_generator::zig_field_name(t_field* tfield) {
    return zig_sanitize_identifier(underscore(tfield->get_name()));
}

string t_zig_generator::zig_function_name(t_function* tfunction) {
    return zig_sanitize_identifier(tfunction->get_name());
}

string t_zig_generator::zig_service_name(t_service* tservice) {
    return zig_sanitize_identifier(tservice->get_name());
}

string t_zig_generator::zig_enum_name(t_enum* tenum) {
    return zig_sanitize_identifier(tenum->get_name());
}

string t_zig_generator::zig_const_name(t_const* tconst) {
    return zig_sanitize_identifier(uppercase(tconst->get_name()));
}

/**
 * Generate struct definition with all methods
 */
void t_zig_generator::generate_struct_definition(t_struct* tstruct, struct_type /* stype */) {
    string struct_name = zig_struct_name(tstruct);
    
    f_gen_ << "pub const " << struct_name << " = struct {\n";
    
    // Generate fields
    generate_struct_fields(tstruct);
    
    // Generate Self type alias
    f_gen_ << "\n    const Self = @This();\n";
    
    // Generate methods
    generate_struct_methods(tstruct);
    
    if (options_.generate_comptime) {
        generate_comptime_info(tstruct);
    }
    
    f_gen_ << "};\n\n";
    
    if (options_.generate_tests) {
        generate_struct_tests(tstruct);
    }
}

/**
 * Generate struct fields
 */
void t_zig_generator::generate_struct_fields(t_struct* tstruct) {
    const vector<t_field*>& members = tstruct->get_sorted_members();
    
    for (auto member : members) {
        string field_name = zig_field_name(member);
        string field_type = to_zig_type(member->get_type());
        
        // Handle optional fields
        if (member->get_req() == t_field::T_OPTIONAL) {
            field_type = "?" + field_type;
        }
        
        f_gen_ << "    " << field_name << ": " << field_type;
        
        // Handle default values
        if (member->get_value() != nullptr) {
            f_gen_ << " = " << to_zig_const_value(member->get_value(), member->get_type());
        } else if (member->get_req() == t_field::T_OPTIONAL) {
            f_gen_ << " = null";
        }
        
        f_gen_ << ",\n";
    }
}

/**
 * Generate struct methods (serialization, deserialization, etc.)
 */
void t_zig_generator::generate_struct_methods(t_struct* tstruct) {
    generate_struct_serialization(tstruct);
    generate_struct_deserialization(tstruct);
    generate_struct_memory_management(tstruct);
}

/**
 * Generate struct serialization method
 */
void t_zig_generator::generate_struct_serialization(t_struct* tstruct) {
    string struct_name = zig_struct_name(tstruct);
    
    f_gen_ << "\n    /// Serialize this struct to a Thrift protocol\n";
    f_gen_ << "    pub fn writeToProtocol(self: *const Self, protocol: *Protocol) ThriftError!void {\n";
    f_gen_ << "        try protocol.writeStructBegin(\"" << tstruct->get_name() << "\");\n";
    
    const vector<t_field*>& members = tstruct->get_sorted_members();
    
    // Add unused parameter handling for empty structs
    if (members.empty()) {
        f_gen_ << "        _ = self;\n";
    }
    
    for (auto member : members) {
        string field_name = zig_field_name(member);
        int32_t field_id = member->get_key();
        
        if (member->get_req() == t_field::T_OPTIONAL) {
            f_gen_ << "        if (self." << field_name << ") |value| {\n";
            f_gen_ << "            try protocol.writeFieldBegin(" << field_id << ", " 
                   << to_protocol_type(member->get_type()) << ");\n";
            generate_serialize_field("value", member->get_type(), 3);
            f_gen_ << "            try protocol.writeFieldEnd();\n";
            f_gen_ << "        }\n";
        } else {
            f_gen_ << "        try protocol.writeFieldBegin(" << field_id << ", " 
                   << to_protocol_type(member->get_type()) << ");\n";
            generate_serialize_field("self." + field_name, member->get_type(), 2);
            f_gen_ << "        try protocol.writeFieldEnd();\n";
        }
    }
    
    f_gen_ << "        try protocol.writeFieldStop();\n";
    f_gen_ << "        try protocol.writeStructEnd();\n";
    f_gen_ << "    }\n";
}

void t_zig_generator::generate_struct_deserialization(t_struct* tstruct) {
    string struct_name = zig_struct_name(tstruct);
    
    const vector<t_field*>& members = tstruct->get_sorted_members();
    bool needs_allocator = false;
    
    // Check if any fields need allocator (for deserialization, we need it for any complex type)
    for (auto member : members) {
        t_type* field_type = member->get_type();
        if (field_type->is_container() || field_type->is_struct() || field_type->is_xception() ||
            (field_type->is_base_type() && ((t_base_type*)field_type)->get_base() == t_base_type::TYPE_STRING)) {
            needs_allocator = true;
            break;
        }
    }
    
    f_gen_ << "\n    /// Deserialize this struct from a Thrift protocol\n";
    if (needs_allocator) {
        f_gen_ << "    pub fn readFromProtocol(protocol: *Protocol, allocator: Allocator) ThriftError!" << struct_name << " {\n";
    } else {
        f_gen_ << "    pub fn readFromProtocol(protocol: *Protocol, allocator: Allocator) ThriftError!" << struct_name << " {\n";
        f_gen_ << "        _ = allocator;\n";
    }
    f_gen_ << "        _ = try protocol.readStructBegin();\n";
    
    // Initialize result struct with default values
    // Use 'var' only if fields will be mutated, otherwise use 'const'
    if (members.empty()) {
        f_gen_ << "        const result = " << struct_name << "{};\n";
    } else {
        f_gen_ << "        var result = " << struct_name << "{\n";
    }
    for (auto member : members) {
        string field_name = zig_field_name(member);
        if (member->get_req() == t_field::T_OPTIONAL) {
            f_gen_ << "            ." << field_name << " = null,\n";
        } else if (member->get_value() != nullptr) {
            f_gen_ << "            ." << field_name << " = " 
                   << to_zig_const_value(member->get_value(), member->get_type()) << ",\n";
        } else {
            f_gen_ << "            ." << field_name << " = " 
                   << to_zig_default_value(member->get_type()) << ",\n";
        }
    }
    if (!members.empty()) {
        f_gen_ << "        };\n";
    }
    
    // Field reading loop
    f_gen_ << "        while (true) {\n";
    f_gen_ << "            const field = try protocol.readFieldBegin();\n";
    f_gen_ << "            if (field.field_type == .STOP) break;\n";
    f_gen_ << "            switch (field.field_id) {\n";
    
    for (auto member : members) {
        f_gen_ << "                " << member->get_key() << " => {\n";
        generate_deserialize_field("result." + zig_field_name(member), member->get_type(), 5);
        f_gen_ << "                },\n";
    }
    
    f_gen_ << "                else => try protocol.skip(field.field_type),\n";
    f_gen_ << "            }\n";
    f_gen_ << "            try protocol.readFieldEnd();\n";
    f_gen_ << "        }\n";
    f_gen_ << "        try protocol.readStructEnd();\n";
    f_gen_ << "        return result;\n";
    f_gen_ << "    }\n";
}

void t_zig_generator::generate_struct_memory_management(t_struct* tstruct) {
    const vector<t_field*>& members = tstruct->get_sorted_members();
    bool has_cleanup = false;
    
    // Check if any fields need cleanup
    for (auto member : members) {
        if (requires_deallocation(member->get_type())) {
            has_cleanup = true;
            break;
        }
    }
    
    // Only generate deinit if there's actual cleanup needed
    if (has_cleanup) {
        f_gen_ << "\n    /// Clean up allocated memory for this struct\n";
        f_gen_ << "    pub fn deinit(self: *Self, allocator: Allocator) void {\n";
        
        bool uses_allocator = false;
        for (auto member : members) {
            if (requires_deallocation(member->get_type())) {
                string field_name = zig_field_name(member);
                bool is_optional = member->get_req() == t_field::T_OPTIONAL;
                generate_deallocation_code("self." + field_name, member->get_type(), is_optional);
                
                // Check if this cleanup actually uses the allocator
                if (member->get_type()->is_base_type()) {
                    t_base_type* tbase = (t_base_type*)member->get_type();
                    if (tbase->get_base() == t_base_type::TYPE_STRING) {
                        uses_allocator = true;
                    }
                }
            }
        }
        
        if (!uses_allocator) {
            f_gen_ << "        _ = allocator;\n";
        }
        
        f_gen_ << "    }\n";
    }
    
    // Generate deep copy method only if needed
    if (has_cleanup) {
        f_gen_ << "\n    /// Create a deep copy of this struct\n";
        f_gen_ << "    pub fn clone(self: *const Self, allocator: Allocator) ThriftError!Self {\n";
        f_gen_ << "        const result = Self{\n";
        
        for (auto member : members) {
            string field_name = zig_field_name(member);
            string field_type = to_zig_type(member->get_type());
            
            if (member->get_req() == t_field::T_OPTIONAL) {
                f_gen_ << "            ." << field_name << " = ";
                if (requires_deallocation(member->get_type())) {
                    f_gen_ << "if (self." << field_name << ") |value| try cloneValue(value, allocator) else null,\n";
                } else {
                    f_gen_ << "self." << field_name << ",\n";
                }
            } else {
                f_gen_ << "            ." << field_name << " = ";
                if (requires_deallocation(member->get_type())) {
                    f_gen_ << "try cloneValue(self." << field_name << ", allocator),\n";
                } else {
                    f_gen_ << "self." << field_name << ",\n";
                }
            }
        }
        
        f_gen_ << "        };\n";
        f_gen_ << "        return result;\n";
        f_gen_ << "    }\n";
        
        // Generate helper method for cloning values
        f_gen_ << "\n    fn cloneValue(value: anytype, allocator: Allocator) ThriftError!@TypeOf(value) {\n";
        f_gen_ << "        const T = @TypeOf(value);\n";
        f_gen_ << "        switch (@typeInfo(T)) {\n";
        f_gen_ << "            .Pointer => |ptr_info| {\n";
        f_gen_ << "                if (ptr_info.size == .Slice) {\n";
        f_gen_ << "                    const copy = try allocator.alloc(ptr_info.child, value.len);\n";
        f_gen_ << "                    std.mem.copy(ptr_info.child, copy, value);\n";
        f_gen_ << "                    return copy;\n";
        f_gen_ << "                }\n";
        f_gen_ << "            },\n";
        f_gen_ << "            .Struct => {\n";
        f_gen_ << "                if (@hasDecl(T, \"clone\")) {\n";
        f_gen_ << "                    return try value.clone(allocator);\n";
        f_gen_ << "                }\n";
        f_gen_ << "            },\n";
        f_gen_ << "            else => {},\n";
        f_gen_ << "        }\n";
        f_gen_ << "        return value;\n";
        f_gen_ << "    }\n";
    }
}

void t_zig_generator::generate_comptime_info(t_struct* tstruct) {
    if (!options_.generate_comptime) return;
    
    const vector<t_field*>& members = tstruct->get_sorted_members();
    
    f_gen_ << "\n    // Compile-time field information\n";
    f_gen_ << "    pub const FieldInfo = struct {\n";
    f_gen_ << "        name: []const u8,\n";
    f_gen_ << "        field_type: FieldType,\n";
    f_gen_ << "        field_id: i16,\n";
    f_gen_ << "        required: bool,\n";
    f_gen_ << "        offset: usize,\n";
    f_gen_ << "    };\n\n";
    
    f_gen_ << "    pub const field_count = " << members.size() << ";\n";
    f_gen_ << "    pub const fields = [_]FieldInfo{\n";
    
    for (auto member : members) {
        string field_name = zig_field_name(member);
        f_gen_ << "        .{\n";
        f_gen_ << "            .name = \"" << field_name << "\",\n";
        f_gen_ << "            .field_type = " << to_protocol_type(member->get_type()) << ",\n";
        f_gen_ << "            .field_id = " << member->get_key() << ",\n";
        f_gen_ << "            .required = " << (member->get_req() != t_field::T_OPTIONAL ? "true" : "false") << ",\n";
        f_gen_ << "            .offset = @offsetOf(Self, \"" << field_name << "\"),\n";
        f_gen_ << "        },\n";
    }
    
    f_gen_ << "    };\n\n";
    
    // Generate field lookup function
    f_gen_ << "    pub fn getFieldInfo(field_id: i16) ?FieldInfo {\n";
    f_gen_ << "        for (fields) |field| {\n";
    f_gen_ << "            if (field.field_id == field_id) return field;\n";
    f_gen_ << "        }\n";
    f_gen_ << "        return null;\n";
    f_gen_ << "    }\n\n";
    
    // Generate field validation function
    f_gen_ << "    pub fn validateFields(self: *const Self) bool {\n";
    f_gen_ << "        _ = self;\n";
    f_gen_ << "        // Field validation logic would go here\n";
    f_gen_ << "        return true;\n";
    f_gen_ << "    }\n\n";
    
    // Generate size calculation function
    f_gen_ << "    pub fn getSerializedSize(self: *const Self) usize {\n";
    f_gen_ << "        var size: usize = 0;\n";
    f_gen_ << "        // Basic struct overhead\n";
    f_gen_ << "        size += @sizeOf(Self);\n";
    f_gen_ << "        // Additional size calculation for dynamic fields would go here\n";
    f_gen_ << "        _ = self;\n";
    f_gen_ << "        return size;\n";
    f_gen_ << "    }\n";
}

void t_zig_generator::generate_struct_tests(t_struct* tstruct) {
    string struct_name = zig_struct_name(tstruct);
    f_gen_ << "test \"" << struct_name << " basic creation\" {\n";
    f_gen_ << "    const instance = " << struct_name << "{};\n";
    f_gen_ << "    _ = instance;\n";
    f_gen_ << "}\n\n";
}

/**
 * Type conversion method - core of the type system
 */
string t_zig_generator::to_zig_type(t_type* ttype) {
    if (ttype->is_base_type()) {
        t_base_type* tbase = (t_base_type*)ttype;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_VOID:     return "void";
            case t_base_type::TYPE_BOOL:     return "bool";
            case t_base_type::TYPE_I8:       return "i8";
            case t_base_type::TYPE_I16:      return "i16";
            case t_base_type::TYPE_I32:      return "i32";
            case t_base_type::TYPE_I64:      return "i64";
            case t_base_type::TYPE_DOUBLE:   return "f64";
            case t_base_type::TYPE_STRING:   
                return tbase->is_binary() ? "[]u8" : "[]const u8";
            case t_base_type::TYPE_UUID:     return "[16]u8";
        }
    } else if (ttype->is_container()) {
        if (ttype->is_map()) {
            t_map* tmap = (t_map*)ttype;
            return "HashMap(" + to_zig_type(tmap->get_key_type()) + 
                   ", " + to_zig_type(tmap->get_val_type()) + ", " +
                   "std.hash_map.DefaultContext(" + to_zig_type(tmap->get_key_type()) + 
                   "), " + options_.allocator_type + ")";
        } else if (ttype->is_set()) {
            t_set* tset = (t_set*)ttype;
            return "HashSet(" + to_zig_type(tset->get_elem_type()) + 
                   ", std.hash_map.DefaultContext(" + to_zig_type(tset->get_elem_type()) + 
                   "), " + options_.allocator_type + ")";
        } else if (ttype->is_list()) {
            t_list* tlist = (t_list*)ttype;
            return "ArrayList(" + to_zig_type(tlist->get_elem_type()) + ")";
        }
    }
    
    // For user-defined types
    return zig_sanitize_identifier(ttype->get_name());
}

/**
 * Generate constant value in Zig syntax
 */
string t_zig_generator::to_zig_const_value(t_const_value* value, t_type* type) {
    if (value == nullptr) {
        return to_zig_default_value(type);
    }
    
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_BOOL:
                return value->get_integer() ? "true" : "false";
            case t_base_type::TYPE_I8:
            case t_base_type::TYPE_I16:
            case t_base_type::TYPE_I32:
            case t_base_type::TYPE_I64:
                return std::to_string(value->get_integer());
            case t_base_type::TYPE_DOUBLE:
                return emit_double_as_string(value->get_double());
            case t_base_type::TYPE_STRING:
                return "\"" + escape_string(value->get_string()) + "\"";
            default:
                break;
        }
    }
    
    // Default fallback
    return "undefined";
}

/**
 * Generate default value for a type
 */
string t_zig_generator::to_zig_default_value(t_type* type) {
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_BOOL:     return "false";
            case t_base_type::TYPE_I8:       return "0";
            case t_base_type::TYPE_I16:      return "0";
            case t_base_type::TYPE_I32:      return "0";
            case t_base_type::TYPE_I64:      return "0";
            case t_base_type::TYPE_DOUBLE:   return "0.0";
            case t_base_type::TYPE_STRING:   return "\"\"";
            case t_base_type::TYPE_UUID:     return "[_]u8{0} ** 16";
            default:
                break;
        }
    } else if (type->is_container()) {
        if (type->is_list()) {
            return "ArrayList(" + to_zig_type(((t_list*)type)->get_elem_type()) + ").init(" + options_.allocator_type + ")";
        } else if (type->is_map()) {
            return "HashMap(" + to_zig_type(((t_map*)type)->get_key_type()) + 
                   ", " + to_zig_type(((t_map*)type)->get_val_type()) + ", " +
                   "std.hash_map.DefaultContext(" + to_zig_type(((t_map*)type)->get_key_type()) + 
                   "), " + options_.allocator_type + ").init(" + options_.allocator_type + ")";
        } else if (type->is_set()) {
            return "HashSet(" + to_zig_type(((t_set*)type)->get_elem_type()) + 
                   ", std.hash_map.DefaultContext(" + to_zig_type(((t_set*)type)->get_elem_type()) + 
                   "), " + options_.allocator_type + ").init(" + options_.allocator_type + ")";
        }
    }
    
    // For user-defined types, use default initialization
    return zig_sanitize_identifier(type->get_name()) + "{}";
}

/**
 * Convert Thrift type to protocol field type
 */
string t_zig_generator::to_protocol_type(t_type* type) {
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_VOID:     return "FieldType.VOID";
            case t_base_type::TYPE_BOOL:     return "FieldType.BOOL";
            case t_base_type::TYPE_I8:       return "FieldType.I8";
            case t_base_type::TYPE_I16:      return "FieldType.I16";
            case t_base_type::TYPE_I32:      return "FieldType.I32";
            case t_base_type::TYPE_I64:      return "FieldType.I64";
            case t_base_type::TYPE_DOUBLE:   return "FieldType.DOUBLE";
            case t_base_type::TYPE_STRING:   return "FieldType.STRING";
            case t_base_type::TYPE_UUID:     return "FieldType.UUID";
        }
    } else if (type->is_container()) {
        if (type->is_list()) {
            return "FieldType.LIST";
        } else if (type->is_set()) {
            return "FieldType.SET";
        } else if (type->is_map()) {
            return "FieldType.MAP";
        }
    } else if (type->is_struct()) {
        return "FieldType.STRUCT";
    } else if (type->is_enum()) {
        return "FieldType.I32";
    }
    
    return "FieldType.STRUCT";
}

/**
 * Generate field serialization code
 */
void t_zig_generator::generate_serialize_field(const string& name, t_type* type, int indent_level) {
    string indent = get_indent(indent_level);
    
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_VOID:
                // Void type doesn't need serialization
                break;
            case t_base_type::TYPE_BOOL:
                f_gen_ << indent << "try protocol.writeBool(" << name << ");\n";
                break;
            case t_base_type::TYPE_I8:
                f_gen_ << indent << "try protocol.writeI8(" << name << ");\n";
                break;
            case t_base_type::TYPE_I16:
                f_gen_ << indent << "try protocol.writeI16(" << name << ");\n";
                break;
            case t_base_type::TYPE_I32:
                f_gen_ << indent << "try protocol.writeI32(" << name << ");\n";
                break;
            case t_base_type::TYPE_I64:
                f_gen_ << indent << "try protocol.writeI64(" << name << ");\n";
                break;
            case t_base_type::TYPE_DOUBLE:
                f_gen_ << indent << "try protocol.writeDouble(" << name << ");\n";
                break;
            case t_base_type::TYPE_STRING:
                if (tbase->is_binary()) {
                    f_gen_ << indent << "try protocol.writeBinary(" << name << ");\n";
                } else {
                    f_gen_ << indent << "try protocol.writeString(" << name << ");\n";
                }
                break;
            case t_base_type::TYPE_UUID:
                f_gen_ << indent << "try protocol.writeUuid(" << name << ");\n";
                break;
        }
    } else if (type->is_container()) {
        generate_serialize_container(name, type, indent_level);
    } else if (type->is_struct()) {
        f_gen_ << indent << "try " << name << ".writeToProtocol(protocol);\n";
    } else if (type->is_enum()) {
        f_gen_ << indent << "try protocol.writeI32(@intFromEnum(" << name << "));\n";
    }
}

/**
 * Generate field deserialization code
 */
void t_zig_generator::generate_deserialize_field(const string& name, t_type* type, int indent_level) {
    string indent = get_indent(indent_level);
    
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        switch (tbase->get_base()) {
            case t_base_type::TYPE_VOID:
                // Void type doesn't need deserialization
                break;
            case t_base_type::TYPE_BOOL:
                f_gen_ << indent << name << " = try protocol.readBool();\n";
                break;
            case t_base_type::TYPE_I8:
                f_gen_ << indent << name << " = try protocol.readI8();\n";
                break;
            case t_base_type::TYPE_I16:
                f_gen_ << indent << name << " = try protocol.readI16();\n";
                break;
            case t_base_type::TYPE_I32:
                f_gen_ << indent << name << " = try protocol.readI32();\n";
                break;
            case t_base_type::TYPE_I64:
                f_gen_ << indent << name << " = try protocol.readI64();\n";
                break;
            case t_base_type::TYPE_DOUBLE:
                f_gen_ << indent << name << " = try protocol.readDouble();\n";
                break;
            case t_base_type::TYPE_STRING:
                if (tbase->is_binary()) {
                    f_gen_ << indent << name << " = try protocol.readBinary(allocator);\n";
                } else {
                    f_gen_ << indent << name << " = try protocol.readString(allocator);\n";
                }
                break;
            case t_base_type::TYPE_UUID:
                f_gen_ << indent << name << " = try protocol.readUuid();\n";
                break;
        }
    } else if (type->is_container()) {
        generate_deserialize_container(name, type, indent_level);
    } else if (type->is_struct()) {
        f_gen_ << indent << name << " = try " << zig_sanitize_identifier(type->get_name()) << ".readFromProtocol(protocol, allocator);\n";
    } else if (type->is_enum()) {
        f_gen_ << indent << name << " = @enumFromInt(try protocol.readI32());\n";
    }
}

/**
 * Generate container serialization code
 */
void t_zig_generator::generate_serialize_container(const string& name, t_type* type, int indent_level) {
    string indent = get_indent(indent_level);
    
    if (type->is_list()) {
        t_list* tlist = (t_list*)type;
        f_gen_ << indent << "try protocol.writeListBegin(" << to_protocol_type(tlist->get_elem_type()) << ", " << name << ".items.len);\n";
        f_gen_ << indent << "for (" << name << ".items) |item| {\n";
        generate_serialize_field("item", tlist->get_elem_type(), indent_level + 1);
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.writeListEnd();\n";
    } else if (type->is_set()) {
        t_set* tset = (t_set*)type;
        f_gen_ << indent << "try protocol.writeSetBegin(" << to_protocol_type(tset->get_elem_type()) << ", " << name << ".count());\n";
        f_gen_ << indent << "var iter = " << name << ".iterator();\n";
        f_gen_ << indent << "while (iter.next()) |item| {\n";
        generate_serialize_field("item", tset->get_elem_type(), indent_level + 1);
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.writeSetEnd();\n";
    } else if (type->is_map()) {
        t_map* tmap = (t_map*)type;
        f_gen_ << indent << "try protocol.writeMapBegin(" << to_protocol_type(tmap->get_key_type()) << ", " 
               << to_protocol_type(tmap->get_val_type()) << ", " << name << ".count());\n";
        f_gen_ << indent << "var iter = " << name << ".iterator();\n";
        f_gen_ << indent << "while (iter.next()) |entry| {\n";
        generate_serialize_field("entry.key_ptr.*", tmap->get_key_type(), indent_level + 1);
        generate_serialize_field("entry.value_ptr.*", tmap->get_val_type(), indent_level + 1);
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.writeMapEnd();\n";
    }
}

/**
 * Generate container deserialization code
 */
void t_zig_generator::generate_deserialize_container(const string& name, t_type* type, int indent_level) {
    string indent = get_indent(indent_level);
    
    if (type->is_list()) {
        t_list* tlist = (t_list*)type;
        f_gen_ << indent << "const list_info = try protocol.readListBegin();\n";
        f_gen_ << indent << name << " = ArrayList(" << to_zig_type(tlist->get_elem_type()) << ").init(allocator);\n";
        f_gen_ << indent << "try " << name << ".ensureTotalCapacity(list_info.size);\n";
        f_gen_ << indent << "for (0..list_info.size) |_| {\n";
        f_gen_ << indent << "    var item: " << to_zig_type(tlist->get_elem_type()) << " = undefined;\n";
        generate_deserialize_field("item", tlist->get_elem_type(), indent_level + 1);
        f_gen_ << indent << "    try " << name << ".append(item);\n";
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.readListEnd();\n";
    } else if (type->is_set()) {
        t_set* tset = (t_set*)type;
        f_gen_ << indent << "const set_info = try protocol.readSetBegin();\n";
        f_gen_ << indent << name << " = HashSet(" << to_zig_type(tset->get_elem_type()) << ", std.hash_map.DefaultContext(" 
               << to_zig_type(tset->get_elem_type()) << "), " << options_.allocator_type << ").init(allocator);\n";
        f_gen_ << indent << "for (0..set_info.size) |_| {\n";
        f_gen_ << indent << "    var item: " << to_zig_type(tset->get_elem_type()) << " = undefined;\n";
        generate_deserialize_field("item", tset->get_elem_type(), indent_level + 1);
        f_gen_ << indent << "    try " << name << ".put(item, {});\n";
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.readSetEnd();\n";
    } else if (type->is_map()) {
        t_map* tmap = (t_map*)type;
        f_gen_ << indent << "const map_info = try protocol.readMapBegin();\n";
        f_gen_ << indent << name << " = HashMap(" << to_zig_type(tmap->get_key_type()) << ", " 
               << to_zig_type(tmap->get_val_type()) << ", std.hash_map.DefaultContext(" 
               << to_zig_type(tmap->get_key_type()) << "), " << options_.allocator_type << ").init(allocator);\n";
        f_gen_ << indent << "for (0..map_info.size) |_| {\n";
        f_gen_ << indent << "    var key: " << to_zig_type(tmap->get_key_type()) << " = undefined;\n";
        f_gen_ << indent << "    var value: " << to_zig_type(tmap->get_val_type()) << " = undefined;\n";
        generate_deserialize_field("key", tmap->get_key_type(), indent_level + 1);
        generate_deserialize_field("value", tmap->get_val_type(), indent_level + 1);
        f_gen_ << indent << "    try " << name << ".put(key, value);\n";
        f_gen_ << indent << "}\n";
        f_gen_ << indent << "try protocol.readMapEnd();\n";
    }
}

/**
 * Generate indentation string
 */
string t_zig_generator::get_indent(int level) {
    string result;
    for (int i = 0; i < level; i++) {
        result += "    ";
    }
    return result;
}

/**
 * Utility method to check if a type requires deallocation
 */
bool t_zig_generator::requires_deallocation(t_type* type) {
    if (type->is_container()) {
        return true;  // Lists, maps, sets all require deallocation
    }
    
    if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        return tbase->get_base() == t_base_type::TYPE_STRING;  // Strings need deallocation
    }
    
    return false;  // Structs and enums don't require deallocation by default
}

/**
 * Generate deallocation code for a field
 */
void t_zig_generator::generate_deallocation_code(const string& name, t_type* type, bool is_optional) {
    if (type->is_container()) {
        if (is_optional) {
            if (type->is_list()) {
                f_gen_ << "        if (" << name << ") |*list| list.deinit();\n";
            } else if (type->is_map() || type->is_set()) {
                f_gen_ << "        if (" << name << ") |*container| container.deinit();\n";
            }
        } else {
            f_gen_ << "        " << name << ".deinit();\n";
        }
    } else if (type->is_base_type()) {
        t_base_type* tbase = (t_base_type*)type;
        if (tbase->get_base() == t_base_type::TYPE_STRING) {
            if (is_optional) {
                f_gen_ << "        if (" << name << ") |str| allocator.free(str);\n";
            } else {
                f_gen_ << "        allocator.free(" << name << ");\n";
            }
        }
    }
}

/**
 * Check if a type is numeric
 */
bool t_zig_generator::is_numeric_type(t_type* type) {
    if (!type->is_base_type()) return false;
    
    t_base_type* tbase = (t_base_type*)type;
    switch (tbase->get_base()) {
        case t_base_type::TYPE_I8:
        case t_base_type::TYPE_I16:
        case t_base_type::TYPE_I32:
        case t_base_type::TYPE_I64:
        case t_base_type::TYPE_DOUBLE:
            return true;
        default:
            return false;
    }
}

/**
 * Check if a type is a container type
 */
bool t_zig_generator::is_container_type(t_type* type) {
    return type->is_container();
}

/**
 * Check if a type is a string type
 */
bool t_zig_generator::is_string_type(t_type* type) {
    if (!type->is_base_type()) return false;
    
    t_base_type* tbase = (t_base_type*)type;
    return tbase->get_base() == t_base_type::TYPE_STRING;
}

/**
 * Register the generator with the Thrift compiler
 */
THRIFT_REGISTER_GENERATOR(zig, "Zig",
    "    package=         Package name for generated code (default: thrift_generated)\n"
    "    allocator=       Default allocator type (default: std.heap.page_allocator)\n"
    "    async=           Generate async/await compatible code (default: false)\n"
    "    comptime=        Use compile-time evaluation (default: true)\n"
    "    tests=           Generate unit tests (default: true)\n"
    "    packed=          Use packed structs (default: false)\n"
    "    format=          Output format: single_file or multi_file (default: single_file)\n")