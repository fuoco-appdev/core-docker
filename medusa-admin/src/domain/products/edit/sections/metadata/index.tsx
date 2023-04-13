import { Product } from "@medusajs/medusa"
import React, { useState } from "react"
import EditIcon from "../../../../../components/fundamentals/icons/edit-icon"
import GearIcon from "../../../../../components/fundamentals/icons/gear-icon"
import PlusIcon from "../../../../../components/fundamentals/icons/plus-icon"
import { ActionType } from "../../../../../components/molecules/actionables"
import Section from "../../../../../components/organisms/section"
import useToggleState from "../../../../../hooks/use-toggle-state"
import EditMetadataModal from "./edit-metadata-modal"
import MetadataTable from "./table"
import { MetadataField } from "../../../../../components/organisms/metadata"
import { useFieldArray, useForm, useWatch } from "react-hook-form"
import { EditFlowMetadataFormType } from "../../../components/metadata-form/edit-flow-metadata-form"

type Props = {
  product: Product
}

const MetadataSection = ({ product }: Props) => {
  const {
    state: editMetadataState,
    close: closeEditMetadata,
    toggle: toggleEditMetadata,
  } = useToggleState()

  const actions: ActionType[] = [
    {
      label: "Edit Metadata",
      onClick: toggleEditMetadata,
      icon: <EditIcon size="20" />,
    },
  ]

  const metadata: MetadataField[] = []
  if (product.metadata?.specs) {
    for (const key in product.metadata.specs) {
      metadata.push({ key: key, value: product.metadata.specs[key] as any })
    }
  }

  const form = useForm<EditFlowMetadataFormType>({
    defaultValues: {
      data: metadata,
    },
  })

  return (
    <>
      <Section title="Metadata" actions={actions}>
        <div className="mt-xlarge">
          <h2 className="inter-large-semibold mb-base">
            Product Metadata{" "}
            <span className="inter-large-regular text-grey-50">
              ({Object.keys(product.metadata?.specs ?? {}).length})
            </span>
          </h2>
          <MetadataTable form={form} product={product} />
        </div>
      </Section>
      <EditMetadataModal
        product={product}
        form={form}
        open={editMetadataState}
        onClose={closeEditMetadata}
      />
    </>
  )
}

export default MetadataSection
