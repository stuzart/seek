module Seek

  class IsaGraphNode

    attr_accessor :object, :child_count

    def initialize(object)
      @object = object
      @child_count = 0
    end

  end

  class IsaGraphGenerator

    def initialize(object)
      @object = object
    end

    def generate(depth: 1, deep: false, include_parents: false, include_self: true)
      hash = { nodes: [], edges: [] }

      depth = deep ? nil : depth

      # Parents and siblings...
      if include_parents
        parents(@object).each do |parent|
          merge_hashes(hash, descendants(parent, depth))
        end

        # All ancestors...
        merge_hashes(hash, ancestors(@object, nil))
      end

      # Self and descendants...
      merge_hashes(hash, descendants(@object, depth))

      hash[:nodes].delete_if { |n| n.object == @object } unless include_self

      hash
    end

    private

    def merge_hashes(hash1, hash2)
      hash1[:nodes] = (hash1[:nodes] + hash2[:nodes]).uniq(&:object)
      hash1[:edges] = (hash1[:edges] + hash2[:edges]).uniq
    end

    def descendants(object, max_depth = nil, depth = 0)
      traverse(:children, object, max_depth, depth)
    end

    def ancestors(object, max_depth = nil, depth = 0)
      traverse(:parents, object, max_depth, depth)
    end

    def traverse(method, object, max_depth = nil, depth = 0)
      node = Seek::IsaGraphNode.new(object)

      children = send(method, object)
      node.child_count = children.count

      nodes = [node]
      edges = []

      if max_depth.nil? || (depth < max_depth) || children.count == 1
        children.each do |child|
          hash = traverse(method, child, max_depth, depth + 1)
          nodes += hash[:nodes]
          edges += hash[:edges]
          edges << (method == :parents ? [child, object] : [object, child])
        end
      end

      { nodes: nodes, edges: edges }
    end

    def children(object)
      associations = associations(object)
      (associations[:children] + associations[:related]).uniq
    end

    def parents(object)
      associations(object)[:parents].uniq
    end

    def associations(object)
      case object
        when Programme
          {
              children: object.projects,
          }
        when Project
          {
              children: object.investigations,
              parents: object.programme ? [object.programme] : []
          }
        when Investigation
          {
              children: object.studies,
              parents: object.projects,
              related: object.publications
          }
        when Study
          {
              children: object.assays,
              parents: [object.investigation],
              related: object.publications
          }
        when Assay
          {
              children: object.assets,
              parents: [object.study],
              related: object.publications
          }
        when Publication
          {
              parents: object.assays | object.studies | object.investigations | object.data_files | object.models
          }
        when DataFile, Model, Sop, Sample, Presentation
          {
              parents: object.assays,
              related: object.publications
          }
      end.reverse_merge!(parents: [], children: [], related: [])
    end

  end
end