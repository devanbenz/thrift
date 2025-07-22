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

#ifndef T_ZIG_GENERATOR_H
#define T_ZIG_GENERATOR_H

#include <string>
#include <fstream>
#include <iostream>
#include <vector>
#include <set>
#include <map>
#include "thrift/generate/t_generator.h"

/**
 * Zig code generator. 
 */
class t_zig_generator : public t_generator {
public:
  t_zig_generator(t_program* program, 
                  const std::map<std::string, std::string>& options,
                  const std::string& option_string);

  ~t_zig_generator() override = default;

  void init_generator() override;
  void close_generator() override;
  std::string display_name() const override;

  void generate_typedef(t_typedef* ttypedef) override;
  void generate_enum(t_enum* tenum) override;
  void generate_const(t_const* tconst) override;
  void generate_struct(t_struct* tstruct) override;
  void generate_service(t_service* tservice) override;
  void generate_xception(t_struct* txception) override;

private:
  /**
   * Configuration options
   */
  struct ZigGeneratorOptions {
    std::string package_name;
    std::string allocator_type;
    bool generate_async;
    bool generate_comptime;
    bool generate_tests;
    bool use_packed_structs;
    std::string output_format;
    
    ZigGeneratorOptions() : 
      package_name("thrift_generated"),
      allocator_type("std.heap.page_allocator"),
      generate_async(false),
      generate_comptime(true),
      generate_tests(true),
      use_packed_structs(false),
      output_format("single_file") {}
  };

  /**
   * Struct generation types
   */
  enum struct_type {
    STRUCT_REGULAR,
    STRUCT_ARGS,
    STRUCT_RESULT,
    STRUCT_EXCEPTION
  };

  /**
   * Generator configuration and state
   */
  std::string gen_dir_;
  ZigGeneratorOptions options_;
  ofstream_with_content_based_conditional_update f_gen_;
  std::set<std::string> imports_;
  std::set<std::string> generated_types_;

  /**
   * Zig language utilities
   */
  std::string to_zig_type(t_type* ttype);
  std::string to_zig_type_name(t_type* ttype);
  std::string to_zig_const_value(t_const_value* value, t_type* type);
  std::string to_zig_default_value(t_type* type);
  std::string to_protocol_type(t_type* type);
  
  /**
   * Naming and formatting utilities
   */
  std::string zig_struct_name(t_struct* tstruct);
  std::string zig_field_name(t_field* tfield);
  std::string zig_function_name(t_function* tfunction);
  std::string zig_service_name(t_service* tservice);
  std::string zig_enum_name(t_enum* tenum);
  std::string zig_const_name(t_const* tconst);
  std::string zig_package_name(t_program* tprogram);
  std::string zig_namespace(t_type* ttype);
  std::string zig_autogen_comment();
  
  /**
   * Keyword and identifier handling
   */
  std::string zig_sanitize_identifier(const std::string& name);
  bool is_zig_reserved_word(const std::string& name);
  std::set<std::string> lang_keywords_for_validation() const override;
  
  /**
   * Type checking utilities
   */
  bool requires_deallocation(t_type* type);
  bool is_numeric_type(t_type* type);
  bool is_container_type(t_type* type);
  bool is_string_type(t_type* type);
  
  /**
   * Struct generation helpers
   */
  void generate_struct_definition(t_struct* tstruct, struct_type stype);
  void generate_struct_fields(t_struct* tstruct);
  void generate_struct_methods(t_struct* tstruct);
  void generate_struct_serialization(t_struct* tstruct);
  void generate_struct_deserialization(t_struct* tstruct);
  void generate_struct_validation(t_struct* tstruct);
  void generate_struct_memory_management(t_struct* tstruct);
  void generate_struct_tests(t_struct* tstruct);
  
  /**
   * Serialization/deserialization
   */
  void generate_serialize_field(const std::string& name, t_type* type, int indent_level = 0);
  void generate_deserialize_field(const std::string& name, t_type* type, int indent_level = 0);
  void generate_serialize_container(const std::string& name, t_type* type, int indent_level = 0);
  void generate_deserialize_container(const std::string& name, t_type* type, int indent_level = 0);
  
  /**
   * Service generation
   */
  void generate_service_interface(t_service* tservice);
  void generate_service_client(t_service* tservice);
  void generate_service_server(t_service* tservice);
  void generate_service_args_result(t_service* tservice);
  void generate_service_method(t_function* tfunction, bool is_async);
  
  /**
   * Compile-time optimization
   */
  void generate_comptime_info(t_struct* tstruct);
  void generate_comptime_type_info(t_type* type);
  void generate_comptime_field_info(t_field* field);
  
  /**
   * Error handling
   */
  void generate_error_types();
  void generate_error_handling(const std::string& context);
  
  /**
   * Memory management
   */
  void generate_allocator_methods(t_struct* tstruct);
  void generate_deallocation_code(const std::string& name, t_type* type, bool is_optional = false);
  void generate_deep_copy_method(t_struct* tstruct);
  
  /**
   * File generation utilities
   */
  void generate_file_header();
  void generate_imports();
  void generate_common_types();
  void generate_program_namespace();
  
  /**
   * Utility methods
   */
  void indent_line(int level = 0);
  std::string get_indent(int level);
  void generate_docstring(const std::string& doc, int indent_level = 0);
  
  /**
   * File and header generation
   */
  
  /**
   * Reserved Zig keywords
   */
  static const std::set<std::string> zig_reserved_words_;
};

#endif // T_ZIG_GENERATOR_H