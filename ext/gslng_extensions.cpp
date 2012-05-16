/**
 * gsl_extension module: provides some simple C functions in cases where a faster version of some
 * Ruby method is really necessary.
 * This could actually a standard C library (not a Ruby extension), but it's easier this way.
 */

#include <ruby.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <iostream>
using namespace std;

/************************* Vector functions *****************************/

static VALUE gsl_vector_map(VALUE self, VALUE ptr) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	for (size_t i = 0; i < v->size; i++)
		gsl_vector_set(v, i, NUM2DBL(rb_yield(rb_float_new(gsl_vector_get(v, i)))));
	
	return self;
}

static VALUE gsl_vector_map_index(VALUE self, VALUE ptr) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	for (size_t i = 0; i < v->size; i++) {
		VALUE vi = ULONG2NUM(i);
		gsl_vector_set(v, i, NUM2DBL(rb_yield(vi)));
	}
	
	return self;
}

static VALUE gsl_vector_each_with_index(VALUE self, VALUE ptr) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	for (size_t i = 0; i < v->size; i++) {
		VALUE vi = ULONG2NUM(i);
		rb_yield_values(2, rb_float_new(gsl_vector_get(v, i)), vi);
	}
	
	return self;
}

static VALUE gsl_vector_each(VALUE self, VALUE ptr) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	for (size_t i = 0; i < v->size; i++)
		rb_yield(rb_float_new(gsl_vector_get(v, i)));
	
	return self;
}

static VALUE gsl_vector_to_a(VALUE self, VALUE ptr) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	
	VALUE array = rb_ary_new2(v->size);
	for (size_t i = 0; i < v->size; i++)
		rb_ary_store(array, i, rb_float_new(gsl_vector_get(v, i)));
	
	return array;
}

static VALUE gsl_vector_from_array(VALUE self, VALUE ptr, VALUE array) {
	gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
	if (v->size != RARRAY_LEN(array)) rb_raise(rb_eRuntimeError, "Sizes differ!");
	
	for (size_t i = 0; i < v->size; i++)
		gsl_vector_set(v, i, NUM2DBL(rb_ary_entry(array, i)));
	
	return self;
}

static VALUE gsl_vector_get_operator(VALUE self, VALUE ptr, VALUE element) {
  gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
  long i = FIX2LONG(element);
  if (i < 0) { i = v->size + i; }
  return rb_float_new(gsl_vector_get(v, (size_t)i));
}

static VALUE gsl_vector_set_operator(VALUE self, VALUE ptr, VALUE element, VALUE value) {
  gsl_vector* v = (gsl_vector*)NUM2ULONG(ptr);
  long i = FIX2LONG(element);
  if (i < 0) { i = v->size + i; }
  gsl_vector_set(v, (size_t)i, NUM2DBL(value));
  return Qnil;
}

static VALUE gsl_vector_eql(VALUE self, VALUE ptr, VALUE other_ptr) {
  gsl_vector* v1 = (gsl_vector*)NUM2ULONG(ptr);
  gsl_vector* v2 = (gsl_vector*)NUM2ULONG(other_ptr);
  if (v1->size != v2->size) return Qfalse;
  for (size_t i = 0; i < v1->size; i++) {
    if (gsl_vector_get(v1, i) != gsl_vector_get(v2, i)) return Qfalse;
  }
  return Qtrue;
}

extern "C" double* gsl_vector_as_array(gsl_vector* v) {
	return v->data;
}

extern "C" gsl_vector_view* gsl_vector_subvector2(gsl_vector* v, size_t offset, size_t stride, size_t n) {
  gsl_vector_view view;
  if (stride != 1) view = gsl_vector_subvector_with_stride(v, offset, stride, n);
  else view = gsl_vector_subvector(v, offset, n);
  
  gsl_vector_view* view_ptr = new gsl_vector_view;
  *view_ptr = view;
  return view_ptr;
}

extern "C" gsl_vector* gsl_vector_view_get_vector(gsl_vector_view* view) {
  return &view->vector;
}

extern "C" void gsl_vector_view_free(gsl_vector_view* v) {
  delete v;
}

/************************* Matrix functions *****************************/

static VALUE gsl_matrix_map(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t size1 = m->size1;
  size_t size2 = m->size2;

	for (size_t i = 0; i < size1; i++)
    for (size_t j = 0; j < size2; j++)
      gsl_matrix_set(m, i, j, NUM2DBL(rb_yield(rb_float_new(gsl_matrix_get(m, i, j)))));

  return self;
}

static VALUE gsl_matrix_map_array(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);

	VALUE array = rb_ary_new2(m->size1);
	for (size_t i = 0; i < m->size1; i++) {
    VALUE row = rb_ary_new2(m->size2);
    for (size_t j = 0; j < m->size2; j++) {
      rb_ary_store(row, j, rb_yield(rb_float_new(gsl_matrix_get(m, i, j))));
    }
    rb_ary_store(array, i, row);
  }

	return array;
}

static VALUE gsl_matrix_map_index(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t size1 = m->size1;
  size_t size2 = m->size2;

	for (size_t i = 0; i < size1; i++)
    for (size_t j = 0; j < size2; j++)
      gsl_matrix_set(m, i, j, NUM2DBL(rb_yield_values(2, ULONG2NUM(i), ULONG2NUM(j))));

  return self;
}

static VALUE gsl_matrix_map_with_index(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t size1 = m->size1;
  size_t size2 = m->size2;

	for (size_t i = 0; i < size1; i++)
    for (size_t j = 0; j < size2; j++)
      gsl_matrix_set(m, i, j, NUM2DBL(rb_yield_values(3, rb_float_new(gsl_matrix_get(m, i, j)), ULONG2NUM(i), ULONG2NUM(j))));

  return self;
}

static VALUE gsl_matrix_each(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t size1 = m->size1;
  size_t size2 = m->size2;

	for (size_t i = 0; i < size1; i++)
    for (size_t j = 0; j < size2; j++)
      rb_yield(rb_float_new(gsl_matrix_get(m, i, j)));

  return self;
}

static VALUE gsl_matrix_each_with_index(VALUE self, VALUE ptr) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t size1 = m->size1;
  size_t size2 = m->size2;

	for (size_t i = 0; i < size1; i++) {
    VALUE vi = ULONG2NUM(i);
    for (size_t j = 0; j < size2; j++)
      rb_yield_values(3, rb_float_new(gsl_matrix_get(m, i, j)), vi, ULONG2NUM(j));
  }
  
  return self;
}

static VALUE gsl_matrix_to_a(VALUE self, VALUE ptr) {
	gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);

	VALUE array = rb_ary_new2(m->size1);
	for (size_t i = 0; i < m->size1; i++) {
    VALUE row = rb_ary_new2(m->size2);
    for (size_t j = 0; j < m->size2; j++) {
      rb_ary_store(row, j, rb_float_new(gsl_matrix_get(m, i, j)));
    }
    rb_ary_store(array, i, row);
  }

	return array;
}

static VALUE gsl_matrix_from_array(VALUE self, VALUE ptr, VALUE array) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  if (m->size1 != RARRAY_LEN(array)) rb_raise(rb_eRuntimeError, "Sizes differ!");

	for (size_t i = 0; i < m->size1; i++) {
    VALUE row = rb_ary_entry(array, i);
    if (m->size2 != RARRAY_LEN(row)) rb_raise(rb_eRuntimeError, "Sizes differ!");

    for (size_t j = 0; j < m->size2; j++)
      gsl_matrix_set(m, i, j, NUM2DBL(rb_ary_entry(row, j)));
  }

	return self;
}

static VALUE gsl_matrix_get_operator(VALUE self, VALUE ptr, VALUE element_i, VALUE element_j) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t i = NUM2ULONG(element_i);
  size_t j = NUM2ULONG(element_j);
  return rb_float_new(gsl_matrix_get(m, i, j));
}

static VALUE gsl_matrix_set_operator(VALUE self, VALUE ptr, VALUE element_i, VALUE element_j, VALUE value) {
  gsl_matrix* m = (gsl_matrix*)NUM2ULONG(ptr);
  size_t i = NUM2ULONG(element_i);
  size_t j = NUM2ULONG(element_j);
  gsl_matrix_set(m, i, j, NUM2DBL(value));
  return Qnil;
}

// Hide the view in a new matrix (gsl_matrix_submatrix)
extern "C" gsl_matrix_view* gsl_matrix_submatrix2(gsl_matrix* m_ptr, size_t x, size_t y, size_t n, size_t m) {
  gsl_matrix_view view = gsl_matrix_submatrix(m_ptr, x, y, n, m);
  gsl_matrix_view* view_ptr = new gsl_matrix_view;
  *view_ptr = view;
  return view_ptr;
}

extern "C" gsl_matrix* gsl_matrix_view_get_matrix(gsl_matrix_view* view) {
  return &view->matrix;
}

extern "C" void gsl_matrix_view_free(gsl_matrix_view* view) {
  delete view;
}

extern "C" gsl_vector_view* gsl_matrix_row_view(gsl_matrix* m_ptr, size_t row, size_t offset, size_t size) {
  gsl_vector_view view = gsl_matrix_subrow(m_ptr, row, offset, size);
  gsl_vector_view* view_ptr = new gsl_vector_view;
  *view_ptr = view;
  return view_ptr;
}

extern "C" gsl_vector_view* gsl_matrix_column_view(gsl_matrix* m_ptr, size_t column, size_t offset, size_t size) {
  gsl_vector_view view = gsl_matrix_subcolumn(m_ptr, column, offset, size);
  gsl_vector_view* view_ptr = new gsl_vector_view;
  *view_ptr = view;
  return view_ptr;
}

extern "C" void gsl_matrix_slide(gsl_matrix* m, ssize_t slide_i, ssize_t slide_j)
{
  gsl_matrix* m2 = gsl_matrix_calloc(m->size1, m->size2);

  for (ssize_t i = 0; (size_t)i < m->size1; i++) {
    for (ssize_t j = 0; (size_t)j < m->size2; j++) {
      if (i - slide_i >= 0 && (size_t)(i - slide_i) < m->size1 && j - slide_j >= 0 && (size_t)(j - slide_j) < m->size2) {
        double v = gsl_matrix_get(m, (size_t)(i - slide_i), (size_t)(j - slide_j));
        gsl_matrix_set(m2, (size_t)i, (size_t)j, v);
      }            
    }
  }

  gsl_matrix_memcpy(m, m2);
  gsl_matrix_free(m2);
}

/************************* Module initialization *****************************/

extern "C" void Init_gslng_extensions(void) {
	VALUE GSLng_module = rb_define_module("GSLng");
	VALUE Backend_module = rb_funcall(GSLng_module, rb_intern("backend"), 0);

	// vector
  rb_define_module_function(Backend_module, "gsl_vector_get_operator", (VALUE(*)(ANYARGS))gsl_vector_get_operator, 2);
  rb_define_module_function(Backend_module, "gsl_vector_set_operator", (VALUE(*)(ANYARGS))gsl_vector_set_operator, 3);
	rb_define_module_function(Backend_module, "gsl_vector_map!", (VALUE(*)(ANYARGS))gsl_vector_map, 1);
	rb_define_module_function(Backend_module, "gsl_vector_map_index!", (VALUE(*)(ANYARGS))gsl_vector_map_index, 1);
	rb_define_module_function(Backend_module, "gsl_vector_each_with_index", (VALUE(*)(ANYARGS))gsl_vector_each_with_index, 1);
	rb_define_module_function(Backend_module, "gsl_vector_each", (VALUE(*)(ANYARGS))gsl_vector_each, 1);
	rb_define_module_function(Backend_module, "gsl_vector_to_a", (VALUE(*)(ANYARGS))gsl_vector_to_a, 1);
	rb_define_module_function(Backend_module, "gsl_vector_from_array", (VALUE(*)(ANYARGS))gsl_vector_from_array, 2);
  rb_define_module_function(Backend_module, "gsl_vector_eql?", (VALUE(*)(ANYARGS))gsl_vector_eql, 2);

  // matrix
	rb_define_module_function(Backend_module, "gsl_matrix_map!", (VALUE(*)(ANYARGS))gsl_matrix_map, 1);
  rb_define_module_function(Backend_module, "gsl_matrix_map_array", (VALUE(*)(ANYARGS))gsl_matrix_map_array, 1);
	rb_define_module_function(Backend_module, "gsl_matrix_map_index!", (VALUE(*)(ANYARGS))gsl_matrix_map_index, 1);
  rb_define_module_function(Backend_module, "gsl_matrix_map_with_index!", (VALUE(*)(ANYARGS))gsl_matrix_map_with_index, 1);
	rb_define_module_function(Backend_module, "gsl_matrix_each_with_index", (VALUE(*)(ANYARGS))gsl_matrix_each_with_index, 1);
	rb_define_module_function(Backend_module, "gsl_matrix_each", (VALUE(*)(ANYARGS))gsl_matrix_each, 1);
	rb_define_module_function(Backend_module, "gsl_matrix_to_a", (VALUE(*)(ANYARGS))gsl_matrix_to_a, 1);
	rb_define_module_function(Backend_module, "gsl_matrix_from_array", (VALUE(*)(ANYARGS))gsl_matrix_from_array, 2);
  rb_define_module_function(Backend_module, "gsl_matrix_get_operator", (VALUE(*)(ANYARGS))gsl_matrix_get_operator, 3);
  rb_define_module_function(Backend_module, "gsl_matrix_set_operator", (VALUE(*)(ANYARGS))gsl_matrix_set_operator, 4);
}
