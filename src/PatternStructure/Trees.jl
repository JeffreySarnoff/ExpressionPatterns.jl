module Trees
export PatternTree, PatternStep, PatternCheck,
       PatternLeaf, PatternNode, PatternGate,
       PatternRoot, PatternHead, Binding,

       ExprHead, SlurpHead,

       nodehead, bindings, insert!, newnode!,
       newleaf!, depth

#-----------------------------------------------------------------------------------
# Type definitions
#-----------------------------------------------------------------------------------

abstract type PatternTree  end
abstract type PatternStep  end
abstract type PatternCheck end
abstract type PatternHead  end


mutable struct PatternRoot <: PatternTree
  child::PatternTree
  PatternRoot() = new()
end

struct PatternNode{PH <: PatternHead} <: PatternTree
  head     :: PH
  step     :: PatternStep
  children :: Vector{PatternTree}
  bindings :: Set{Symbol}
  depth    :: Int
end

struct PatternLeaf <: PatternTree
end

struct Binding <: PatternCheck
  name::Symbol
end

mutable struct PatternGate <: PatternTree
  check    :: PatternCheck
  bindings :: Set{Symbol}
  depth    :: Int
  child    :: PatternTree

  PatternGate(check::Any,     depth) = new(check, Set{Symbol}(), depth)
  PatternGate(check::Binding, depth) = new(check, Set{Symbol}([check.name]), depth)
end

abstract type SlurpHead <: PatternHead end

struct ExprHead <: PatternHead
  sym::Symbol
end

const SingleChildNode = Union{PatternGate, PatternRoot}

#-----------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------

function nodehead(node::PatternNode)
  isa(node.head, ExprHead) ? node.head.sym : (:slurp)
end

bindings(leaf::PatternLeaf) = Set{Symbol}()
bindings(gate::PatternGate) = gate.bindings
bindings(node::PatternNode) = node.bindings

depth(gate::PatternGate) = gate.depth
depth(node::PatternNode) = node.depth

function makenode(head, step, depth)
  children   = PatternTree[]
  bindings   = Set{Symbol}()
  slurpdepth = isa(head, SlurpHead) ? depth+1 : depth

  PatternNode(head, step, children, bindings, slurpdepth)
end

import Base: insert!

function insert!(parent::PatternNode, child)
  push!(parent.children, child)
  union!(parent.bindings, bindings(child))
end

function insert!(parent::PatternGate, child)
  parent.child = child
  union!(parent.bindings, bindings(child))
end

function insert!(parent::PatternRoot, child)
  parent.child = child
end

function newnode!(head, step, parent::PatternTree)
  node = makenode(head, step, depth(parent))
  insert!(parent, node)
  return node
end

function newleaf!(check, parent::PatternTree)
  leaf = PatternLeaf()
  gate = PatternGate(check, depth(parent))
  insert!(gate, leaf)
  insert!(parent, gate)
  return leaf
end

#-----------------------------------------------------------------------------------
end
